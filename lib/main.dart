import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
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
      if (topbids[id]!.value.value != value) {
        topbids[id]!.value = (email: email, value: value);
      }
    } else {
      throw Exception("Malformed Data Recieved! ${p.map((k, v) => MapEntry(k, v.runtimeType))}");
    }
  }).subscribe();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

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
  MainPage({super.key});
  final ValueNotifier<bool> viewMode = ValueNotifier(false);

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
                                  child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: GridTile(
                                          footer: Tooltip(
                                              message: snapshot.data![i].description,
                                              child: ListenableBuilder(
                                                  listenable: topbids[snapshot.data![i].id]!,
                                                  builder: (context, _) {
                                                    Bid top = topbids[snapshot.data![i].id]!.value;
                                                    return Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text("\$${top.value}",
                                                              style: Theme.of(context)
                                                                  .textTheme
                                                                  .labelLarge),
                                                          Expanded(
                                                              child: Text(top.email,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  textAlign: TextAlign.right,
                                                                  style: Theme.of(context)
                                                                      .textTheme
                                                                      .labelLarge))
                                                        ]);
                                                  })),
                                          child: Stack(alignment: Alignment.topCenter, children: [
                                            Text(snapshot.data![i].name,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.titleMedium),
                                            snapshot.data![i].image
                                          ])))))
                          : Center(
                              child: CarouselSlider.builder(
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, i, _) => Card(
                                      child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                Expanded(child: snapshot.data![i].image),
                                                Text(snapshot.data![i].name,
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context).textTheme.titleLarge),
                                                if (snapshot.data![i].description?.isNotEmpty ??
                                                    false)
                                                  Text(
                                                      snapshot.data![i].description!
                                                          .replaceAll("\n", " | "),
                                                      textAlign: TextAlign.center,
                                                      style: Theme.of(context).textTheme.bodyLarge),
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
                                              ]))),
                                  options: CarouselOptions(
                                      enlargeCenterPage: true,
                                      viewportFraction: 0.8,
                                      enlargeFactor: 0.2,
                                      aspectRatio: 4 / 5,
                                      height: MediaQuery.of(context).size.width > 400
                                          ? MediaQuery.of(context).size.width
                                          : null)))))));
}

enum ItemCategory { games, miscellaneous, giftcards, sports }

typedef Item = ({int id, String name, String? description, ItemCategory category, Widget image});
Future<List<Item>> fetchItems() async {
  PostgrestList resp = await Supabase.instance.client
      .from("items")
      .select<PostgrestList>("id, name, description, category, image")
      .order("id");
  List<Item> out = [];
  for (Map<String, dynamic> row in resp) {
    if (row
        case {
          'id': int id,
          'name': String name,
          'description': String? description,
          'category': String category,
          'image': String? imageid
        }) {
      category = category.toLowerCase().replaceAll(" ", "");
      out.add((
        id: id,
        name: name,
        description: description,
        category: ItemCategory.values.firstWhere((e) => e.name == category),
        image: //imgfile == null
            //?
            const Center(child: Icon(Icons.image_not_supported_rounded, size: 48))
        //: CachedNetworkImage(
        //    imageUrl: Supabase.instance.client.storage.from("items").getPublicUrl(imgfile))
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
