import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'components/carouselpage.dart';
import 'components/gridpage.dart';

late final SharedPreferences prefs;

void main() async {
  await Supabase.initialize(
      url: 'https://bhueoihalnchbflzaseh.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJodWVvaWhhbG5jaGJmbHphc2VoIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTc1ODM1MTUsImV4cCI6MjAxMzE1OTUxNX0.lnAvR3s3IIX8cQweaahpxwlSkqauqUT7b6Cdu7Cfchw');
  Supabase.instance.client.realtime.channel("bids").on(RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: "*", schema: "public", table: "bids"), (p, [_]) {
    if (p?["new"] == null) return;
    if ((p["new"] as Map).isEmpty) return; // can't handle deletes :/
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
  runApp(MaterialApp(
      title: 'Pasta Auction',
      theme:
          ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.red), useMaterial3: true),
      darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
          useMaterial3: true),
      home: ScaffoldShell()));
}

class ScaffoldShell extends StatelessWidget {
  final GlobalKey<NavigatorState> _navKey = GlobalKey();
  final ValueNotifier<int> navIndex = ValueNotifier(0);
  ScaffoldShell({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      bottomNavigationBar: ListenableBuilder(
          listenable: navIndex,
          builder: (context, _) => NavigationBar(
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: "Grid View"),
                    NavigationDestination(
                        icon: Icon(Icons.width_normal_rounded), label: "Carousel"),
                    NavigationDestination(icon: Icon(Icons.gavel_rounded), label: "Your Bids")
                  ],
                  onDestinationSelected: (i) {
                    navIndex.value = i;
                    _navKey.currentState!
                        .pushReplacementNamed(const ["/grid", "/carousel", "/bids"][i]);
                  },
                  selectedIndex: navIndex.value,
                  height: 40,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide)),
      body: Navigator(
          key: _navKey,
          initialRoute: "/grid",
          onGenerateRoute: (settings) {
            Widget? w = const {
              "/grid": GridPage(),
              "/carousel": CarouselPage(),
              "/bids": Placeholder()
            }[settings.name];
            return w == null
                ? null
                : MaterialPageRoute(settings: settings, builder: (context) => w);
          },
          onUnknownRoute: (settings) {
            _navKey.currentState!.pushReplacementNamed("/grid");
            return null;
          }));
}

class MissingImage extends StatelessWidget {
  const MissingImage({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Icon(Icons.image_not_supported_rounded, size: 48));
}

enum ItemCategory { games, giftcards, sports, dvds, miscellaneous, unknown }

typedef Item = ({
  int id,
  String name,
  String? description,
  ItemCategory category,
  List<Widget> images
});
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
        category: ItemCategory.values
            .firstWhere((e) => e.name == category, orElse: () => ItemCategory.unknown),
        images: imagenames
                ?.map((imagename) => CachedNetworkImage(
                    errorWidget: (context, err, _) =>
                        Center(child: Icon(Icons.broken_image_outlined, color: Colors.red[800])),
                    imageUrl:
                        Supabase.instance.client.storage.from("itempics").getPublicUrl(imagename)))
                .toList() ??
            []
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
