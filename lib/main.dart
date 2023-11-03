import 'package:flutter/material.dart';
import 'package:pastaauction/components/bidspage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'components/carouselpage.dart';
import 'components/gridpage.dart';
import 'supa.dart';

late final SharedPreferences prefs;

void main() async {
  await Supabase.initialize(
      url: 'https://bhueoihalnchbflzaseh.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJodWVvaWhhbG5jaGJmbHphc2VoIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTc1ODM1MTUsImV4cCI6MjAxMzE1OTUxNX0.lnAvR3s3IIX8cQweaahpxwlSkqauqUT7b6Cdu7Cfchw');
  prefs = await SharedPreferences.getInstance();
  items = await fetchItems();
  if (items.indexWhere((item) => !topbids.containsKey(item.id)) != -1) await reloadTopBids();
  Supabase.instance.client.realtime.channel("bids").on(RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: "*", schema: "public", table: "bids"), (p, [_]) {
    if (p?["new"] == null) return;
    if ((p["new"] as Map).isEmpty) {
      // handle delete calls
      reloadTopBids();
    } else if (p["new"]
        case {
          "bidderemail": String email,
          "id": String uuid,
          "item": int itemid,
          "time": String _,
          "value": int value
        }) {
      if (!topbids.containsKey(itemid)) {
        // if there aren't any bids, then this must be the highest!
        topbids[itemid] = ValueNotifier((uuid: uuid, email: email, value: value));
      } else if (topbids[itemid]!.value.uuid == p["old"]?["id"]) {
        // handle updates
        if (topbids[itemid]!.value.value <= value) {
          // if increasing, great! then it must still be the highest
          topbids[itemid]!.value = (uuid: uuid, email: email, value: value);
        } else {
          // if decreasing, we need to rerun checks
          getItemTopBid(itemid).then((topbid) => topbids[itemid]!.value = topbid);
        }
      } else if (p["eventType"] == "INSERT" && topbids[itemid]!.value.value < value) {
        // handle inserts
        topbids[itemid]!.value = (uuid: uuid, email: email, value: value);
      }
    } else {
      throw Exception(
          "Malformed Data Recieved! ${p?["new"].map((k, v) => MapEntry(k, v.runtimeType))}");
    }
  }).subscribe();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      title: 'Pasta Auction',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          inputDecorationTheme: const InputDecorationTheme(border: UnderlineInputBorder()),
          useMaterial3: true),
      darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
          inputDecorationTheme: const InputDecorationTheme(border: UnderlineInputBorder()),
          useMaterial3: true),
      home: ScaffoldShell()));
}

class ScaffoldShell extends StatelessWidget {
  final GlobalKey<NavigatorState> _navKey = GlobalKey();
  final ValueNotifier<int> navIndex = ValueNotifier(prefs.getInt("navIndex") ?? 0);
  ScaffoldShell({super.key}) {
    navIndex.addListener(() => prefs.setInt("navIndex", navIndex.value));
  }

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
          initialRoute: const ["/grid", "/carousel", "/bids"][navIndex.value],
          onGenerateRoute: (settings) {
            Widget? w = {
              "/grid": GridPage(),
              "/carousel": const CarouselPage(),
              "/bids": const BidsPage()
            }[settings.name];
            return w == null
                ? null
                : MaterialPageRoute(settings: settings, builder: (context) => w);
          }));
}

class MissingImage extends StatelessWidget {
  const MissingImage({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Icon(Icons.image_not_supported_rounded, size: 48));
}

late final List<Item> items;
final Map<int, ValueNotifier<Bid>> topbids = {};

Future<void> reloadTopBids() => Future.wait([getAllStartBids(), getAllTopBids()])
    .then((data) => data.reduce((accum, add) => accum..addAll(add)).forEach((id, bid) {
          if (!topbids.containsKey(id)) {
            topbids[id] = ValueNotifier(bid);
          } else {
            topbids[id]!.value = bid;
          }
        }));
