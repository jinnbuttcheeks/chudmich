import 'package:flutter/material.dart';
import 'package:immich_mobile/theme/solid/solid_tokens.dart';

/// Flat surface: solid fill, 1 px hairline border, optional pre-baked shadow. No blur, no saveLayer.
class SolidSurface extends StatelessWidget {
  const SolidSurface({
    super.key,
    required this.child,
    this.radius = SolidTokens.radiusCard,
    this.padding,
    this.color,
    this.bordered = true,
    this.floating = false,
    this.clip = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  /// Overrides the paper fill (for example the accent for a primary button, or a scrim over photos).
  final Color? color;
  final bool bordered;

  /// Adds the floating shadow, for bars, sheets and toasts. Leave off inside scrolling lists.
  final bool floating;

  /// Clips the child to the rounded shape (for images and list rows that fill the card).
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.solid;
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? tokens.paper,
        borderRadius: borderRadius,
        border: bordered ? Border.fromBorderSide(tokens.hairline) : null,
        boxShadow: floating ? SolidTokens.floatingShadow : null,
      ),
      child: _wrap(padding == null ? child : Padding(padding: padding!, child: child), borderRadius),
    );
  }

  Widget _wrap(Widget content, BorderRadius borderRadius) =>
      clip ? ClipRRect(borderRadius: borderRadius, child: content) : content;
}

/// Full-width strip for app bars. [condense] (0..1) fades a solid background and hairline in as
/// content scrolls under it.
class SolidBar extends StatelessWidget {
  const SolidBar({super.key, this.condense = 1, this.edge = Alignment.bottomCenter, this.child});

  final double condense;

  /// Side that carries the hairline (bottom for top bars, top for bottom bars).
  final Alignment edge;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.solid;
    final t = condense.clamp(0.0, 1.0);
    final line = BorderSide(color: tokens.border.withValues(alpha: tokens.border.a * t));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.canvas.withValues(alpha: t),
        border: Border(bottom: edge.y > 0 ? line : BorderSide.none, top: edge.y < 0 ? line : BorderSide.none),
      ),
      child: child ?? const SizedBox.expand(),
    );
  }
}
