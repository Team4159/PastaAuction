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
              var filteredItems = items
                  .where((it) => it.name.toLowerCase().contains(searched))
                  .toList()
                ..sort((a, b) => topbids[b.id]!.value.value - topbids[a.id]!.value.value);
              return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  sliver: SliverGrid.builder(
                      itemCount: filteredItems.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300),
                      itemBuilder: (context, i) {
                        var itemCard = Card(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                                onTap: () => showDialog(
                                    context: context,
                                    builder: (context) => BidMenu(item: filteredItems[i])),
                                child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(children: [
                                      Expanded(
                                          child: Stack(
                                              alignment: Alignment.topCenter,
                                              fit: StackFit.expand,
                                              children: [
                                            filteredItems[i].images.isEmpty
                                                ? const MissingImage()
                                                : filteredItems[i].images.length == 1
                                                    ? filteredItems[i].images.first
                                                    : IgnorePointer(
                                                        child: FlutterCarousel(
                                                            items: filteredItems[i].images,
                                                            options: CarouselOptions(
                                                                autoPlay: true,
                                                                autoPlayInterval: Duration(
                                                                    seconds: filteredItems[i]
                                                                            .images
                                                                            .length *
                                                                        2),
                                                                enableInfiniteScroll: true,
                                                                viewportFraction: 1,
                                                                slideIndicator:
                                                                    CircularStaticIndicator(
                                                                        itemSpacing: 16,
                                                                        indicatorRadius: 4),
                                                                physics:
                                                                    const NeverScrollableScrollPhysics()))),
                                            Text("#${filteredItems[i].id} ${filteredItems[i].name}",
                                                textAlign: TextAlign.center,
                                                style:
                                                    Theme.of(context).brightness == Brightness.dark
                                                        ? Theme.of(context)
                                                            .textTheme
                                                            .titleMedium!
                                                            .copyWith(shadows: const [
                                                            Shadow(
                                                              offset: Offset(4.0, 4.0),
                                                              blurRadius: 2.0,
                                                              color: Colors.black,
                                                            )
                                                          ])
                                                        : Theme.of(context).textTheme.titleMedium)
                                          ])),
                                      const SizedBox(height: 9),
                                      Builder(builder: (context) {
                                        Widget priceWidget = ListenableBuilder(
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
                                                        style:
                                                            Theme.of(context).textTheme.labelLarge))
                                              ]);
                                            });
                                        if (filteredItems[i].description == null) {
                                          return priceWidget;
                                        }
                                        return Tooltip(
                                            message: filteredItems[i].description,
                                            triggerMode: TooltipTriggerMode.tap,
                                            child: priceWidget);
                                      })
                                    ]))));
                        if (filteredItems[i].msrp < 50) {
                          return Padding(padding: const EdgeInsets.all(4), child: itemCard);
                        }
                        return Padding(
                            padding: const EdgeInsets.all(4),
                            child: DecoratedBox(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                          color: HSVColor.fromAHSV(
                                                  0.7,
                                                  (120.0 * (filteredItems[i].msrp - 50) / 50.0)
                                                      .clamp(0, 240),
                                                  1,
                                                  1)
                                              .toColor(),
                                          blurRadius: 2,
                                          spreadRadius: 2)
                                    ]),
                                child: itemCard));
                      }));
            })
      ]);
}
