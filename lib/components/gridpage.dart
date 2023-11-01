import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

import '../main.dart';
import 'bidmenu.dart';

class GridPage extends StatelessWidget {
  final TextEditingController searchTerm = TextEditingController();
  GridPage({super.key});

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
        SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            sliver: SliverToBoxAdapter(
                child: TextField(
                    controller: searchTerm,
                    decoration: InputDecoration(
                        hintText: "Search",
                        suffix: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => searchTerm.clear()))))),
        ListenableBuilder(
            listenable: searchTerm,
            builder: (context, _) {
              String searched = searchTerm.value.text.toLowerCase();
              var filteredItems =
                  items.where((it) => it.name.toLowerCase().contains(searched)).toList();
              return SliverGrid.builder(
                  itemCount: filteredItems.length,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300),
                  itemBuilder: (context, i) => Card(
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                          onTap: () => showDialog(
                              context: context,
                              builder: (context) => BidMenu(item: filteredItems[i])),
                          child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: GridTile(
                                  child: Column(children: [
                                Expanded(
                                    child: Stack(
                                        alignment: Alignment.topCenter,
                                        fit: StackFit.expand,
                                        children: [
                                      filteredItems[i].images.isEmpty
                                          ? const MissingImage()
                                          : IgnorePointer(
                                              child: FlutterCarousel(
                                                  items: filteredItems[i].images,
                                                  options: CarouselOptions(
                                                      autoPlay: true,
                                                      autoPlayInterval: Duration(
                                                          seconds: filteredItems[i].images.length),
                                                      viewportFraction: 1,
                                                      slideIndicator: CircularStaticIndicator(
                                                          itemSpacing: 16, indicatorRadius: 4),
                                                      physics:
                                                          const NeverScrollableScrollPhysics()))),
                                      Text(filteredItems[i].name,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(shadows: const [
                                            Shadow(
                                              offset: Offset(4.0, 4.0),
                                              blurRadius: 2.0,
                                              color: Colors.black,
                                            )
                                          ]))
                                    ])),
                                const SizedBox(height: 9),
                                Tooltip(
                                    message: filteredItems[i].description,
                                    triggerMode: TooltipTriggerMode.tap,
                                    child: ListenableBuilder(
                                        listenable: topbids[filteredItems[i].id]!,
                                        builder: (context, _) {
                                          var top = topbids[filteredItems[i].id]!.value;
                                          return Row(mainAxisSize: MainAxisSize.min, children: [
                                            Text("\$${top.value}",
                                                style: Theme.of(context).textTheme.labelLarge),
                                            Expanded(
                                                child: Text(top.email,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.right,
                                                    style: Theme.of(context).textTheme.labelLarge))
                                          ]);
                                        }))
                              ]))))));
            })
      ]);
}
