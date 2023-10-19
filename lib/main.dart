import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
      url: 'https://bhueoihalnchbflzaseh.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJodWVvaWhhbG5jaGJmbHphc2VoIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTc1ODM1MTUsImV4cCI6MjAxMzE1OTUxNX0.lnAvR3s3IIX8cQweaahpxwlSkqauqUT7b6Cdu7Cfchw');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
  Supabase.instance.client.realtime.onMessage(print);
  Supabase.instance.client.realtime.onError(print);
  Supabase.instance.client.realtime
      .channel("bids")
      .on(RealtimeListenTypes.postgresChanges, ChannelFilter(schema: "public", table: "bids"), (p0,
          [p]) {
    print(p0);
    print(p);
  }).subscribe((n, [a]) => print(n));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Pasta Auction',
      theme:
          ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.red), useMaterial3: true),
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
      body: SafeArea(
          child: FutureBuilder(
              future: fetchItems(),
              builder: (context, snapshot) => !snapshot.hasData
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
                                  maxCrossAxisExtent: 250),
                              itemBuilder: (context, i) => GridTile(
                                  footer: Tooltip(
                                      message: snapshot.data![i].description,
                                      child: ListenableBuilder(
                                          listenable: topbids[snapshot.data![i].id]!,
                                          builder: (context, _) {
                                            Bid top = topbids[snapshot.data![i].id]!.value;
                                            return Row(children: [
                                              Text("\$${top.value}"),
                                              const Expanded(child: SizedBox()),
                                              Text(top.email)
                                            ]);
                                          })),
                                  child: Stack(children: [
                                    Text(snapshot.data![i].name),
                                    snapshot.data![i].image
                                  ])))
                          : CarouselSlider.builder(
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, i, _) => Material(
                                      child: Column(children: [
                                    snapshot.data![i].image,
                                    Text(snapshot.data![i].name),
                                    if (snapshot.data![i].description?.isNotEmpty ?? false)
                                      Text(snapshot.data![i].description!),
                                    ListenableBuilder(
                                        listenable: topbids[snapshot.data![i].id]!,
                                        builder: (context, _) {
                                          Bid top = topbids[snapshot.data![i].id]!.value;
                                          return Row(children: [
                                            Text("\$${top.value}"),
                                            const Expanded(child: SizedBox()),
                                            Text(top.email)
                                          ]);
                                        })
                                  ])),
                              options: CarouselOptions(enlargeCenterPage: true))))));
}

enum ItemCategory { games, miscellaneous, giftcards, sports }

typedef Item = ({int id, String name, String? description, ItemCategory category, Widget image});
Future<List<Item>> fetchItems() async {
  PostgrestList resp = await Supabase.instance.client
      .from("items")
      .select<PostgrestList>("id, name, description, category, storage.objects (name)")
      .order("id");
  List<Item> out = [];
  for (Map<String, dynamic> _ in resp) {
    if (resp
        case {
          'id': int id,
          'name': String name,
          'description': String? description,
          'category': String category,
          'image': String? imgfile
        }) {
      category = category.toLowerCase().replaceAll(" ", "");
      out.add((
        id: id,
        name: name,
        description: description,
        category: ItemCategory.values.firstWhere((e) => e.name == category),
        image: imgfile == null
            ? const Center(child: Icon(Icons.image_not_supported_rounded, size: 48))
            : CachedNetworkImage(
                imageUrl: Supabase.instance.client.storage.from("items").getPublicUrl(imgfile))
      ));
    } else {
      throw Exception("Malformed Data Recieved!");
    }
  }
  return out;
}

typedef Bid = ({String email, int value});
final Map<int, ValueNotifier<Bid>> topbids = {};
Future<Bid> getItemTopBid(int itemid) => Supabase.instance.client
    .rpc("getitemtopbid", params: {"itemid": itemid})
    .single()
    .then((record) => (email: record.bidderemail as String, value: record.value as int));
