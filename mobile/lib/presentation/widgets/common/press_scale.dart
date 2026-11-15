import 'package:flutter/widgets.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';

/// Scales [child] down while a pointer is pressed on it and springs back on release.
///
/// It only observes pointer events, so it never competes with taps, long presses
/// or drags handled by the child. Does nothing when the user prefers reduced motion.
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

  void _setPressed(bool pressed) {
    if (!widget.enabled || PremiumMotion.reduced(context)) {
      return;
    }
    if (pressed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: widget.scale).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
