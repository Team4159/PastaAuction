import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
      url: 'https://bhueoihalnchbflzaseh.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJodWVvaWhhbG5jaGJmbHphc2VoIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTc1ODM1MTUsImV4cCI6MjAxMzE1OTUxNX0.lnAvR3s3IIX8cQweaahpxwlSkqauqUT7b6Cdu7Cfchw');
  Supabase.instance.client.realtime.channel("bids").on(RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: "*", schema: "public", table: "bids"), (p, [_]) {
    if (p?["new"] == null) return;
    if (p["new"]
        case {
          "bidderemail": String email,
          "id": String _,
          "item": int id,
          "time": String _,
          "value": int value
        }) {
      if (topbids[id] == null) {
        topbids[id] = ValueNotifier((email: email, value: value));
      } else if (topbids[id]!.value.value != value) {
        topbids[id]!.value = (email: email, value: value);
      }
    } else {
      throw Exception(
          "Malformed Data Recieved! ${p?["new"].map((k, v) => MapEntry(k, v.runtimeType))}");
    }
  }).subscribe();
  prefs = await SharedPreferences.getInstance();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

late final SharedPreferences prefs;
const double bidmargin = 1.1;

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Pasta Auction',
      theme:
          ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.red), useMaterial3: true),
      darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
          useMaterial3: true),
      home: MainPage());
}

class MainPage extends StatelessWidget {
  MainPage({super.key}) {
    viewMode.addListener(() => prefs.setBool("viewMode", viewMode.value));
  }
  final ValueNotifier<bool> viewMode = ValueNotifier(prefs.getBool("viewMode") ?? false);

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text("Pasta Auction"),
          automaticallyImplyLeading: false,
          centerTitle: true,
          excludeHeaderSemantics: true),
      floatingActionButton: FloatingActionButton(
          onPressed: () => viewMode.value = !viewMode.value,
          child: ListenableBuilder(
              listenable: viewMode,
              builder: (context, _) =>
                  Icon(viewMode.value ? Icons.width_normal_rounded : Icons.grid_view_rounded))),
      body: SafeArea(
          child: FutureBuilder(
              future: fetchItems(),
              builder: (context, snapshot) => !snapshot.hasData || snapshot.data == null
                  ? snapshot.hasError
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                              Icon(Icons.warning_rounded, color: Colors.red[700], size: 50),
                              const SizedBox(height: 20),
                              Text(snapshot.error.toString())
                            ])
                      : const Center(child: CircularProgressIndicator())
                  : ListenableBuilder(
                      listenable: viewMode,
                      builder: (context, _) => viewMode.value
                          ? GridView.builder(
                              itemCount: snapshot.data!.length,
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 300),
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              itemBuilder: (context, i) => Card(
                                  clipBehavior: Clip.hardEdge,
                                  child: InkWell(
                                      onTap: () => showDialog(
                                          context: context,
                                          builder: (context) => BidMenu(item: snapshot.data![i])),
                                      child: Padding(
                                          padding: const EdgeInsets.all(18),
                                          child: GridTile(
                                              child: Column(children: [
                                                  Expanded(child: Stack(alignment: Alignment.topCenter, children: [
                                                
                                                snapshot.data![i].images[0], // TODO: add multi image
                                                Text(snapshot.data![i].name,
                                                    textAlign: TextAlign.center,
                                                    
                                                    style: Theme.of(context).textTheme.titleMedium!.copyWith(backgroundColor: Colors.black87))
                                              ])),
                                              const SizedBox(height: 9),
                                              Tooltip(
                                                  message: snapshot.data![i].description,
                                                  triggerMode: TooltipTriggerMode.tap,
                                                  child: ListenableBuilder(
                                                      listenable: topbids[snapshot.data![i].id]!,
                                                      builder: (context, _) {
                                                        Bid top =
                                                            topbids[snapshot.data![i].id]!.value;
                                                        return Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text("\$${top.value}",
                                                                  style: Theme.of(context)
                                                                      .textTheme
                                                                      .labelLarge),
                                                              Expanded(
                                                                  child: Text(top.email,
                                                                      overflow:
                                                                          TextOverflow.ellipsis,
                                                                      textAlign: TextAlign.right,
                                                                      style: Theme.of(context)
                                                                          .textTheme
                                                                          .labelLarge))
                                                            ]);
                                                      }))
                                              ]))))))
                          : Center(
                              child: CarouselSlider.builder(
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, i, _) => Card(
                                      clipBehavior: Clip.hardEdge,
                                      child: InkWell(
                                          onTap: () => showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  BidMenu(item: snapshot.data![i])),
                                          child: Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                  children: [
                                                    Expanded(child: snapshot.data![i].images[0]), // TODO add multi image
                                                    const SizedBox(height: 12),
                                                    Text(snapshot.data![i].name,
                                                        textAlign: TextAlign.center,
                                                        style:
                                                            Theme.of(context).textTheme.titleLarge),
                                                    if (snapshot.data![i].description?.isNotEmpty ??
                                                        false)
                                                      Text(
                                                          snapshot.data![i].description!
                                                              .replaceAll("\n", " | "),
                                                          textAlign: TextAlign.center,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge),
                                                    ListenableBuilder(
                                                        listenable: topbids[snapshot.data![i].id]!,
                                                        builder: (context, _) {
                                                          Bid top =
                                                              topbids[snapshot.data![i].id]!.value;
                                                          return Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Text("\$${top.value}",
                                                                    style: Theme.of(context)
                                                                        .textTheme
                                                                        .labelLarge),
                                                                Expanded(
                                                                    child: Text(top.email,
                                                                        textAlign: TextAlign.right,
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .labelLarge))
                                                              ]);
                                                        })
                                                  ])))),
                                  options: CarouselOptions(
                                      enlargeCenterPage: true,
                                      viewportFraction: 0.8,
                                      enlargeFactor: 0.2,
                                      aspectRatio: 4 / 5,
                                      initialPage: prefs.getInt("initialCarousel") ?? 0,
                                      onPageChanged: (i, _) => prefs.setInt("initialCarousel", i),
                                      height: MediaQuery.of(context).size.width > 400
                                          ? MediaQuery.of(context).size.width
                                          : null)))))));
}

class BidMenu extends StatelessWidget {
  final Item item;
  final GlobalKey<FormState> _formkey = GlobalKey();
  final Map<bool, int?> stupid = {true: null};
  BidMenu({super.key, required this.item});

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
      widthFactor: MediaQuery.of(context).size.width > 500 ? 0.5 : 1.0,
      child: Dialog(
          alignment: Alignment.center,
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                  key: _formkey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Place Bid", style: Theme.of(context).textTheme.headlineMedium),
                        Text("'${item.name}'", overflow: TextOverflow.ellipsis),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                  flex: 3,
                                  child: TextFormField(
                                      initialValue: prefs.getString("email"),
                                      decoration: const InputDecoration(
                                          border: UnderlineInputBorder(), labelText: "Your Email"),
                                      validator: (value) =>
                                          (value?.isEmpty ?? true) ? "Required" : null,
                                      onSaved: (String? email) => email == null
                                          ? prefs.remove("email")
                                          : prefs.setString("email", email))),
                              const SizedBox(width: 20),
                              Flexible(
                                  flex: 1,
                                  child: ListenableBuilder(
                                      listenable: topbids[item.id]!,
                                      builder: (context, _) => TextFormField(
                                            initialValue:
                                                (topbids[item.id]!.value.value * bidmargin)
                                                    .ceil()
                                                    .toString(),
                                            decoration: const InputDecoration(
                                                border: UnderlineInputBorder(),
                                                prefixText: "\$",
                                                labelText: "Bid Amount"),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly
                                            ],
                                            validator: (value) => value == null
                                                ? "Required"
                                                : int.parse(value) >=
                                                        topbids[item.id]!.value.value * bidmargin
                                                    ? null
                                                    : "Bid too low!",
                                            onSaved: (value) => stupid[true] =
                                                value == null ? null : int.parse(value),
                                          )))
                            ]),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: () {
                              if (!_formkey.currentState!.validate()) return;
                              _formkey.currentState!.save();
                              if (stupid[true] == null) return;
                              Supabase.instance.client.from("bids").insert({
                                "item": item.id,
                                "bidderemail": prefs.getString("email"),
                                "value": stupid[true]
                              }).then((value) {
                                _formkey.currentState!.reset();
                                Navigator.pop(context);
                              }).catchError((e) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(e.toString())));
                              });
                            },
                            child: const Text("Submit Bid"))
                      ])))));
}

enum ItemCategory { games, miscellaneous, giftcards, sports, dvds }

typedef Item = ({int id, String name, String? description, ItemCategory category, List<Widget> images});
Future<List<Item>> fetchItems() async {
  PostgrestList resp = await Supabase.instance.client
      .from("items")
      .select<PostgrestList>("id, name, description, category, images")
      .order("id");
  List<Item> out = [];
  for (Map<String, dynamic> row in resp) {
    if (row
        case {
          'id': int id,
          'name': String name,
          'description': String? description,
          'category': String category,
          'images': List<dynamic>? imagenames
        }) {
      category = category.toLowerCase().replaceAll(" ", "");
      out.add((
        id: id,
        name: name,
        description: description,
        category: ItemCategory.values.firstWhere((e) => e.name == category),
        images: imagenames == null ?
           [const Center(child: Icon(Icons.image_not_supported_rounded, size: 48))]
        : imagenames.map((imagename) => CachedNetworkImage(
           imageUrl: Supabase.instance.client.storage.from("itempics").getPublicUrl(imagename))).toList()
      ));
    } else {
      throw Exception("Malformed Data Recieved! ${row.map((k, v) => MapEntry(k, v.runtimeType))}");
    }
  }
  if (topbids.length != out.length) {
    await Future.forEach(
        out.map((n) => n.id), (id) async => topbids[id] = ValueNotifier(await getItemTopBid(id)));
  }
  return out;
}

typedef Bid = ({String email, int value});
final Map<int, ValueNotifier<Bid>> topbids = {};
Future<Bid> getItemTopBid(int itemid) =>
    Supabase.instance.client.rpc("getitemtopbid", params: {"itemid": itemid}).then((record) =>
        (email: record["bidderemail"] as String? ?? "Starting Bid", value: record["value"] as int));
