import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// App-wide signal: is a vertical scrollable moving right now?
///
/// Glass that sits over a scrolling grid swaps its live backdrop blur for a
/// denser static tint while this is true (see [GlassScrollGate]) and goes back
/// to the live blur once scrolling has been idle for a moment.
abstract final class GlassScrollActivity {
  static final ValueNotifier<bool> scrolling = ValueNotifier<bool>(false);
}

/// Feeds [GlassScrollActivity] from the scroll notifications of its subtree.
/// Mount exactly one, above the Navigator: the flag is shared, so nested
/// listeners would clear it while another scroll is still running.
///
/// Only vertical scrolling counts (rails and carousels do not). The end of a
/// scroll is debounced by [idleDelay], so a fling that ends and restarts (or a
/// scrubber drag, which jumps) does not flip the glass back and forth.
class GlassScrollActivityListener extends StatefulWidget {
  const GlassScrollActivityListener({
    super.key,
    required this.child,
    this.idleDelay = const Duration(milliseconds: 220),
  });

  final Widget child;
  final Duration idleDelay;

  @override
  State<GlassScrollActivityListener> createState() => _GlassScrollActivityListenerState();
}

class _GlassScrollActivityListenerState extends State<GlassScrollActivityListener> {
  Timer? _idle;
  bool _owns = false;

  bool _onNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      // Every notification re-arms the timer, so a scrollable that is disposed
      // mid-scroll (no end notification) cannot leave the glass static.
      _owns = true;
      GlassScrollActivity.scrolling.value = true;
      _idle?.cancel();
      _idle = Timer(widget.idleDelay, _settle);
    }
    return false;
  }

  void _settle() {
    _idle = null;
    _owns = false;
    GlassScrollActivity.scrolling.value = false;
  }

  @override
  void dispose() {
    _idle?.cancel();
    if (_owns) {
      GlassScrollActivity.scrolling.value = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(onNotification: _onNotification, child: widget.child);
  }
}

/// Builds with `fake` from 0 (idle: live glass) to 1 (scrolling: static glass),
/// eased so the swap reads as a tint change instead of a pop. Its ticker only
/// runs during a transition; when idle nothing is scheduled.
class GlassScrollGate extends StatefulWidget {
  const GlassScrollGate({super.key, required this.builder, this.activity});

  final Widget Function(BuildContext context, double fake) builder;

  /// Test hook; defaults to [GlassScrollActivity.scrolling].
  final ValueListenable<bool>? activity;

  @override
  State<GlassScrollGate> createState() => _GlassScrollGateState();
}

class _GlassScrollGateState extends State<GlassScrollGate> with SingleTickerProviderStateMixin {
  late final AnimationController _fake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final CurvedAnimation _curve = CurvedAnimation(parent: _fake, curve: Curves.easeOut);
  late ValueListenable<bool> _activity;

  @override
  void initState() {
    super.initState();
    _activity = widget.activity ?? GlassScrollActivity.scrolling;
    _activity.addListener(_onActivity);
    _fake.value = _activity.value ? 1 : 0;
  }

  @override
  void didUpdateWidget(GlassScrollGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.activity ?? GlassScrollActivity.scrolling;
    if (next != _activity) {
      _activity.removeListener(_onActivity);
      _activity = next..addListener(_onActivity);
      _onActivity();
    }
  }

  void _onActivity() {
    final target = _activity.value;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _fake.value = target ? 1 : 0;
    } else if (target) {
      unawaited(_fake.forward());
    } else {
      unawaited(_fake.reverse());
    }
  }

  @override
  void dispose() {
    _activity.removeListener(_onActivity);
    _curve.dispose();
    _fake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _curve, builder: (context, _) => widget.builder(context, _curve.value));
  }
}
