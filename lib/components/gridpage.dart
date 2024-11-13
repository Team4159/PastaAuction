import 'dart:math' show pow;

import 'package:flutter/material.dart';

import '../bids.dart' show topbids;
import '../items.dart' show Item, ItemCategory, items;
import '../main.dart' show prefs;
import 'bidmenu.dart';
import 'carousel.dart';

class GridPage extends StatefulWidget {
  GridPage({super.key});

  @override
  State<StatefulWidget> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
  static const _SCALE = 8 / (150 * 150);
  late final TextEditingController searchTerm = TextEditingController();
  ItemCategory? searchCategory = null;
  late String sortMethod = sortingFunctions.keys.contains(prefs.getString("sort"))
      ? prefs.getString("sort")!
      : sortingFunctions.keys.first;

  @override
  Widget build(BuildContext context) {
    String searchText = searchTerm.value.text.toLowerCase();
    var filteredItems = items
        .where((it) =>
            (searchText.isEmpty || it.name.toLowerCase().contains(searchText)) &&
            (searchCategory == null || it.category == searchCategory))
        .toList()
      ..sort(sortingFunctions[sortMethod]);
    return Scaffold(
        body: CustomScrollView(slivers: [
          SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              sliver: SliverToBoxAdapter(
                  child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 55, minHeight: 55),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(
                            child: TextField(
                                controller: searchTerm,
                                onChanged: (value) => setState(() {}),
                                decoration: InputDecoration(
                                    hintText: "Search",
                                    suffix: IconButton(
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: searchTerm.clear)))),
                        const SizedBox(width: 8),
                        DropdownButton(
                            items: [
                              DropdownMenuItem(child: Text("All Items"), value: null),
                              for (var category in ItemCategory.values)
                                DropdownMenuItem(
                                    child: ConstrainedBox(
                                        constraints: BoxConstraints(maxWidth: 70),
                                        child: Text(
                                            category.name.substring(0, 1).toUpperCase() +
                                                category.name.substring(1),
                                            overflow: TextOverflow.ellipsis)),
                                    value: category)
                            ],
                            value: searchCategory,
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            icon: Icon(Icons.filter_alt_outlined),
                            onChanged: (category) => setState(() => searchCategory = category)),
                        DropdownButton(
                            items: [
                              for (var sort in sortingFunctions.keys)
                                DropdownMenuItem(
                                    child: Text(sort), value: sort, alignment: Alignment.center)
                            ],
                            value: sortMethod,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            menuWidth: 90,
                            icon: Icon(Icons.sort_rounded),
                            onChanged: (sort) => setState(() {
                                  sortMethod = sort ?? sortingFunctions.keys.first;
                                  prefs.setString("sort", sortMethod);
                                }))
                      ])))),
          SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              sliver: SliverGrid.builder(
                  itemCount: filteredItems.length,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 375),
                  itemBuilder: (context, i) {
                    var item = filteredItems[i];
                    var topbid = topbids[item.id]!;
                    return Card(
                        elevation: item.msrp <= 50 ? 0 : _SCALE * pow(item.msrp - 50, 2),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                            onTap: () => showDialog(
                                context: context,
                                builder: (context) => BidMenu(item: filteredItems[i])),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(
                                  child: Stack(fit: StackFit.expand, children: [
                                filteredItems[i].images.isEmpty
                                    ? const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Icon(
                                          Icons.image_not_supported_rounded,
                                          size: 72,
                                        ))
                                    : Carousel(filteredItems[i].images),
                                Align(
                                    alignment: Alignment.topLeft,
                                    child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.only(bottomRight: Radius.circular(8)),
                                        child: ColoredBox(
                                            color:
                                                Theme.of(context).colorScheme.surfaceContainerHigh,
                                            child: Padding(
                                                padding: EdgeInsets.only(
                                                    left: 8, right: 6, top: 6, bottom: 4),
                                                child: ListenableBuilder(
                                                    listenable: topbid,
                                                    builder: (context, child) => RichText(
                                                        text: TextSpan(children: [
                                                          if (topbid.value.bidder != null)
                                                            TextSpan(
                                                                text: topbid.value.bidder! + " - ",
                                                                style: Theme.of(context)
                                                                    .textTheme
                                                                    .titleMedium!
                                                                    .copyWith(
                                                                        color: Colors.green[700])),
                                                          TextSpan(
                                                              text: "\$${topbid.value.value}",
                                                              style: Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium!
                                                                  .copyWith(color: Colors.green))
                                                        ]),
                                                        textAlign: TextAlign.center))))))
                              ])),
                              item.images.isEmpty ? const Divider() : const SizedBox(height: 8),
                              Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12, right: 12, bottom: 12, top: 4),
                                  child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Expanded(
                                            child: Text(item.name,
                                                textAlign: TextAlign.left,
                                                softWrap: false,
                                                overflow: TextOverflow.fade,
                                                style: Theme.of(context).textTheme.titleMedium)),
                                        Text("#${item.id}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(color: Colors.grey))
                                      ]))
                            ])));
                  }))
        ]),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).pushReplacementNamed("/bids"),
            icon: Icon(Icons.gavel_rounded),
            label: Text("My Bids")));
  }
}

final Map<String, int Function(Item, Item)> sortingFunctions = {
  "Top Bid": (a, b) =>
      (topbids[b.id]?.value.value ?? b.startingbid) - (topbids[a.id]?.value.value ?? a.startingbid),
  "MSRP": (a, b) => b.msrp - a.msrp,
  "A-Z": (a, b) => a.name.compareTo(b.name),
  "ID #": (a, b) => a.id - b.id
};
