import 'package:flutter/material.dart';

import '../main.dart';
import '../supa.dart';
import 'bidmenu.dart';

class BidsPage extends StatelessWidget {
  const BidsPage({super.key});

  @override
  Widget build(BuildContext context) => !prefs.containsKey("email")
      ? const NoBidWidget()
      : FutureBuilder(
          future: getMyTopBids(prefs.getString("email")!).then((bidmap) => bidmap.entries.toList()),
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
              : snapshot.data!.isEmpty
                  ? const NoBidWidget()
                  : ListView.builder(
                      primary: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, i) {
                        Bid mybid =
                            snapshot.data![i].value; // note: modification of past bid not supported
                        Item item = items.firstWhere((item) => item.id == snapshot.data![i].key);
                        return ListenableBuilder(
                            listenable: topbids[item.id]!,
                            builder: (context, _) {
                              Bid topbid = topbids[item.id]!.value;
                              if (topbid.email == prefs.getString("email")) mybid = topbid;
                              return ListTile(
                                  leading: item.images.isNotEmpty
                                      ? ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 100),
                                          child: item.images[0])
                                      : null,
                                  title: Text(item.name, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      mybid == topbid ? "Top Bid" : "Outbid by ${topbid.email}"),
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
                      }));
}

class NoBidWidget extends StatelessWidget {
  const NoBidWidget({super.key});

  @override
  Widget build(BuildContext context) => const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Text("You haven't bid on anything yet!")]); // TODO add cute pics!
}
