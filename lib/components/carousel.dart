import 'package:flutter/material.dart';

class Carousel extends StatelessWidget {
  late final PageController _controller = PageController();
  final ValueNotifier<int> _page = ValueNotifier(0);
  final List<Widget> items;

  Carousel(this.items, {super.key});

  @override
  Widget build(BuildContext context) => items.length == 1
      ? items[0]
      : Stack(fit: StackFit.expand, alignment: Alignment.center, children: [
          PageView(children: items, controller: _controller, onPageChanged: (p) => _page.value = p),
          Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  onPressed: () => _controller.previousPage(
                      duration: Durations.medium1, curve: Curves.easeOutSine),
                  padding: EdgeInsets.zero,
                  iconSize: 48,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  icon: Icon(Icons.arrow_left_rounded))),
          Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                  onPressed: () =>
                      _controller.nextPage(duration: Durations.medium1, curve: Curves.easeOutSine),
                  padding: EdgeInsets.zero,
                  iconSize: 48,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  icon: Icon(Icons.arrow_right_rounded))),
          Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                  padding: EdgeInsets.all(8),
                  child: ListenableBuilder(
                      listenable: _page,
                      builder: (context, _) => Theme(
                          data: ThemeData(
                              iconTheme: IconThemeData(
                                  size: 16,
                                  color:
                                      Theme.of(context).colorScheme.surfaceBright.withAlpha(100))),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (int i = 0; i < items.length; i++)
                                  _page.value == i
                                      ? const Icon(Icons.circle)
                                      : const Icon(Icons.circle_outlined)
                              ])))))
        ]);
}
