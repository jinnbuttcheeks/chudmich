import 'package:flutter/widgets.dart';

/// Empty sliver as tall as the bottom safe-area inset.
///
/// Inside the tab shell that inset includes the floating navigation bar, so the
/// last items of a [CustomScrollView] can be scrolled clear of it. Elsewhere it
/// is just the system navigation inset.
class BottomInsetSliver extends StatelessWidget {
  const BottomInsetSliver({super.key, this.extra = 0});

  /// Additional breathing room under the last item.
  final double extra;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + extra));
  }
}
