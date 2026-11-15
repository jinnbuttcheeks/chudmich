import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';

/// Scales [child] down while a pointer is pressed on it and springs back on release.
///
/// It only observes pointer events, so it never competes with taps, long presses
/// or drags handled by the child. The scale starts after a short hold and is
/// cancelled as soon as the pointer moves, so scrolling a list never shrinks tiles.
/// Does nothing when the user prefers reduced motion.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = PremiumTokens.pressedScale, this.enabled = true});

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: PremiumMotion.fast);
  late final CurvedAnimation _curve = CurvedAnimation(parent: _controller, curve: PremiumMotion.snappy);

  static const _holdDelay = Duration(milliseconds: 70);

  Timer? _holdTimer;
  Offset? _downPosition;

  void _onDown(PointerDownEvent event) {
    if (!widget.enabled || PremiumMotion.reduced(context)) {
      return;
    }
    _downPosition = event.position;
    _holdTimer?.cancel();
    _holdTimer = Timer(_holdDelay, _controller.forward);
  }

  void _onMove(PointerMoveEvent event) {
    final down = _downPosition;
    if (down != null && (event.position - down).distance > kTouchSlop) {
      _release();
    }
  }

  void _release() {
    _downPosition = null;
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_controller.value > 0) {
      unawaited(_controller.reverse());
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: widget.scale).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
