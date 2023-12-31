import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

import '../main.dart';
import 'bidmenu.dart';

class CarouselPage extends StatelessWidget {
  const CarouselPage({super.key});

  @override
  Widget build(BuildContext context) {
    var filteredItems = items.where((item) => item.msrp >= 40).toList();
    return Center(
        child: FlutterCarousel.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, i, _) => Card(
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                    onTap: () => showDialog(
                        context: context, builder: (context) => BidMenu(item: filteredItems[i])),
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                          Expanded(
                              child: filteredItems[i].images.isEmpty
                                  ? const MissingImage()
                                  : filteredItems[i].images.length == 1
                                      ? filteredItems[i].images[0]
                                      : ManualCarousel(filteredItems[i].images)),
                          const SizedBox(height: 12),
                          Text(filteredItems[i].name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge),
                          if (filteredItems[i].description?.isNotEmpty ?? false)
                            Text(filteredItems[i].description!.replaceAll("\n", " | "),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge),
                          ListenableBuilder(
                              listenable: topbids[filteredItems[i].id]!,
                              builder: (context, _) {
                                var top = topbids[filteredItems[i].id]!.value;
                                return Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text("\$${top.value}",
                                      style: Theme.of(context).textTheme.labelLarge),
                                  Expanded(
                                      child: Text(top.email,
                                          textAlign: TextAlign.right,
                                          style: Theme.of(context).textTheme.labelLarge))
                                ]);
                              })
                        ])))),
            options: CarouselOptions(
                enlargeCenterPage: true,
                viewportFraction: 0.8,
                aspectRatio: 4 / 5,
                showIndicator: false,
                enableInfiniteScroll: true,
                initialPage: prefs.getInt("initialCarousel") ?? 0,
                onPageChanged: (i, _) => prefs.setInt("initialCarousel", i),
                height: MediaQuery.of(context).size.width > 400
                    ? MediaQuery.of(context).size.width
                    : null)));
  }
}

class ManualCarousel extends StatelessWidget {
  final List<Widget> images;
  final ValueNotifier<int> page = ValueNotifier(0);
  ManualCarousel(this.images, {super.key});

  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.center, children: [
        ListenableBuilder(
            listenable: page,
            builder: (context, _) => IndexedStack(index: page.value, children: images)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton.filledTonal(
              onPressed: () => page.value = normalize(page.value - 1, 0, images.length),
              icon: const Icon(Icons.chevron_left_rounded)),
          IconButton.filledTonal(
              onPressed: () => page.value = normalize(page.value + 1, 0, images.length),
              icon: const Icon(Icons.chevron_right_rounded))
        ])
      ]);
}

int normalize(int val, int low, int high) {
  if (val < low) return val + (high - low) * ((low - val) / (high - low).toDouble()).ceil();
  if (val >= high) return (val - low) % (high - low) + low;
  return val;
}
