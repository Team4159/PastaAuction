import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

import '../main.dart';
import 'bidmenu.dart';

class GridPage extends StatelessWidget {
  const GridPage({super.key});

  @override
  Widget build(BuildContext context) => GridView.builder(
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemBuilder: (context, i) => Card(
          clipBehavior: Clip.hardEdge,
          child: InkWell(
              onTap: () =>
                  showDialog(context: context, builder: (context) => BidMenu(item: items[i])),
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: GridTile(
                      child: Column(children: [
                    Expanded(
                        child:
                            Stack(alignment: Alignment.topCenter, fit: StackFit.expand, children: [
                      items[i].images.isEmpty
                          ? const MissingImage()
                          : IgnorePointer(
                              child: FlutterCarousel(
                                  items: items[i].images,
                                  options: CarouselOptions(
                                      autoPlay: true,
                                      autoPlayInterval: Duration(seconds: items[i].images.length),
                                      viewportFraction: 1,
                                      slideIndicator: CircularStaticIndicator(
                                          itemSpacing: 16, indicatorRadius: 4),
                                      physics: const NeverScrollableScrollPhysics()))),
                      Text(items[i].name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(shadows: const [
                            Shadow(
                              offset: Offset(4.0, 4.0),
                              blurRadius: 2.0,
                              color: Colors.black,
                            )
                          ]))
                    ])),
                    const SizedBox(height: 9),
                    Tooltip(
                        message: items[i].description,
                        triggerMode: TooltipTriggerMode.tap,
                        child: ListenableBuilder(
                            listenable: topbids[items[i].id]!,
                            builder: (context, _) {
                              var top = topbids[items[i].id]!.value;
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
}
