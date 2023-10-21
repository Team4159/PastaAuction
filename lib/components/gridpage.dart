import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

import '../main.dart';
import 'bidmenu.dart';

class GridPage extends StatelessWidget {
  const GridPage({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder(
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
          : GridView.builder(
              itemCount: snapshot.data!.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              itemBuilder: (context, i) => Card(
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                      onTap: () => showDialog(
                          context: context, builder: (context) => BidMenu(item: snapshot.data![i])),
                      child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: GridTile(
                              child: Column(children: [
                            Expanded(
                                child: Stack(
                                    alignment: Alignment.topCenter,
                                    fit: StackFit.expand,
                                    children: [
                                  snapshot.data![i].images.isEmpty
                                      ? const MissingImage()
                                      : IgnorePointer(
                                          child: FlutterCarousel(
                                              items: snapshot.data![i].images,
                                              options: CarouselOptions(
                                                  autoPlay: true,
                                                  autoPlayInterval: Duration(
                                                      seconds: snapshot.data![i].images.length),
                                                  viewportFraction: 1,
                                                  slideIndicator: CircularStaticIndicator(
                                                      itemSpacing: 16, indicatorRadius: 4),
                                                  physics: const NeverScrollableScrollPhysics()))),
                                  Text(snapshot.data![i].name,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(backgroundColor: Colors.black87))
                                ])),
                            const SizedBox(height: 9),
                            Tooltip(
                                message: snapshot.data![i].description,
                                triggerMode: TooltipTriggerMode.tap,
                                child: ListenableBuilder(
                                    listenable: topbids[snapshot.data![i].id]!,
                                    builder: (context, _) {
                                      Bid top = topbids[snapshot.data![i].id]!.value;
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
                          ])))))));
}
