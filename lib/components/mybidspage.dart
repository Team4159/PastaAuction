import 'package:flutter/material.dart';

import '../items.dart';
import '../main.dart';
import '../bids.dart';
import 'bidmenu.dart';

class MyBidsPage extends StatelessWidget {
  const MyBidsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      body: !prefs.containsKey("email")
          ? Center(child: NoBids())
          : FutureBuilder(
              future:
                  getUserBids(prefs.getString("email")!).then((bidmap) => bidmap.entries.toList()),
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
                  : ListView.builder(
                      primary: true,
                      itemCount: snapshot.data!.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Tooltip(
                                  message: "Change your email in the bid menu!",
                                  triggerMode: TooltipTriggerMode.tap,
                                  child: Text("Bids for ${prefs.getString("email")}",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headlineSmall)));
                        }
                        i--;
                        if (snapshot.data!.isEmpty) return NoBids();
                        Bid mybid =
                            snapshot.data![i].value; // note: modification of past bid not supported
                        Item item = items.firstWhere((item) => item.id == snapshot.data![i].key);
                        return ListenableBuilder(
                            listenable: topbids[item.id]!,
                            builder: (context, _) {
                              Bid topbid = topbids[item.id]!.value;
                              if (topbid.bidder == null || mybid.value > topbid.value) {
                                // if my bid has been deleted, remove me
                                snapshot.data!.remove(snapshot.data![i]);
                                return const SizedBox();
                              }
                              if (topbid.bidder == prefs.getString("email")) mybid = topbid;
                              return ListTile(
                                  leading: item.images.isNotEmpty
                                      ? ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 100),
                                          child: item.images[0])
                                      : null,
                                  title: Text(item.name, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      mybid == topbid ? "Top Bid" : "Outbid by ${topbid.bidder}"),
                                  trailing: mybid == topbid
                                      ? Text("\$${mybid.value}")
                                      : Text("-\$${topbid.value - mybid.value}",
                                          style: const TextStyle(color: Colors.red)),
                                  leadingAndTrailingTextStyle:
                                      Theme.of(context).textTheme.titleLarge,
                                  enabled: mybid != topbid,
                                  onTap: () => showDialog(
                                      context: context, builder: (context) => BidMenu(item: item)));
                            });
                      })),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).pushReplacementNamed("/"),
          icon: Icon(Icons.category_rounded),
          label: Text("Items")));
}

class NoBids extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Flexible(
                flex: 2,
                child: Text("Bid on something and it'll appear here!",
                    softWrap: true, textAlign: TextAlign.center)),
            const SizedBox(height: 24),
            Flexible(flex: 3, child: Image.asset("nobids.png", scale: 0.5, fit: BoxFit.contain))
          ]);
}
