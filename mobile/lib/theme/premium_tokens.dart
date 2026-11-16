import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Spring based [Curve]. Plays a [SpringSimulation] from 0 to 1 and stretches it
/// over the time the spring needs to settle, so it can drive any
/// [AnimationController] or tween while keeping a physical feel.
class SpringCurve extends Curve {
  SpringCurve({double dampingRatio = 0.86, double stiffness = 380, double mass = 1})
    : _spring = SpringSimulation(
        SpringDescription.withDampingRatio(mass: mass, stiffness: stiffness, ratio: dampingRatio),
        0,
        1,
        0,
      ) {
    var t = 0.0;
    while (!_spring.isDone(t) && t < 3) {
      t += 1 / 120;
    }
    _settleSeconds = t <= 0 ? 1 / 120 : t;
  }

  final SpringSimulation _spring;
  late final double _settleSeconds;

  /// Time the spring needs to come to rest. Use it as the animation duration.
  Duration get settleDuration => Duration(milliseconds: (_settleSeconds * 1000).ceil());

  @override
  double transformInternal(double t) => _spring.x(t * _settleSeconds);
}

/// Motion vocabulary shared by every animated surface.
abstract final class PremiumMotion {
  /// Default spring: a hint of overshoot, used for position and size changes.
  static final SpringCurve standard = SpringCurve();

  /// Quick and tight, for press feedback and toggles.
  static final SpringCurve snappy = SpringCurve(dampingRatio: 0.9, stiffness: 700);

  /// Soft and slow, for large surfaces such as sheets and shared elements.
  static final SpringCurve gentle = SpringCurve(dampingRatio: 0.92, stiffness: 220);

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);

  /// Whether the user asked the platform to reduce motion.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns [Duration.zero] when motion is reduced.
  static Duration resolve(BuildContext context, Duration duration) => reduced(context) ? Duration.zero : duration;
}

/// Rect tween that eases with a spring curve, used for hero flights.
class SpringRectTween extends RectTween {
  SpringRectTween({super.begin, super.end});

  @override
  Rect? lerp(double t) => super.lerp(PremiumMotion.gentle.transform(t));
}

/// Design tokens that sit on top of the Material [ColorScheme] so dynamic color,
/// the primary color setting and light/dark mode keep driving every surface.
@immutable
class PremiumTokens extends ThemeExtension<PremiumTokens> {
  const PremiumTokens({
    required this.floatingSurface,
    required this.floatingBorder,
    required this.floatingShadow,
    required this.activePill,
    required this.onActivePill,
    required this.inactiveIcon,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  // Shape
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusSheet = 28;
  static const double radiusPill = 999;

  // Spacing (4pt grid)
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;

  // Floating navigation bar
  static const double navBarHeight = 64;
  static const double navBarGap = 12;
  static const double navBarHorizontalMargin = 20;

  // Press feedback
  static const double pressedScale = 0.97;

  /// Space reserved at the bottom of scrolling content for the floating bar.
  static double navBarInset(BuildContext context) => navBarHeight + navBarGap + MediaQuery.paddingOf(context).bottom;

  final Color floatingSurface;
  final Color floatingBorder;
  final Color floatingShadow;
  final Color activePill;
  final Color onActivePill;
  final Color inactiveIcon;
  final Color skeletonBase;
  final Color skeletonHighlight;

  factory PremiumTokens.fromScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return PremiumTokens(
      floatingSurface: scheme.surfaceContainerHigh.withValues(alpha: isDark ? 0.72 : 0.78),
      floatingBorder: scheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.07),
      floatingShadow: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
      activePill: scheme.primary.withValues(alpha: isDark ? 0.28 : 0.16),
      onActivePill: scheme.primary,
      inactiveIcon: scheme.onSurfaceVariant,
      skeletonBase: scheme.surfaceContainer,
      skeletonHighlight: scheme.surfaceContainerHighest,
    );
  }

  @override
  PremiumTokens copyWith({
    Color? floatingSurface,
    Color? floatingBorder,
    Color? floatingShadow,
    Color? activePill,
    Color? onActivePill,
    Color? inactiveIcon,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return PremiumTokens(
      floatingSurface: floatingSurface ?? this.floatingSurface,
      floatingBorder: floatingBorder ?? this.floatingBorder,
      floatingShadow: floatingShadow ?? this.floatingShadow,
      activePill: activePill ?? this.activePill,
      onActivePill: onActivePill ?? this.onActivePill,
      inactiveIcon: inactiveIcon ?? this.inactiveIcon,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  PremiumTokens lerp(ThemeExtension<PremiumTokens>? other, double t) {
    if (other is! PremiumTokens) {
      return this;
    }
    return PremiumTokens(
      floatingSurface: Color.lerp(floatingSurface, other.floatingSurface, t)!,
      floatingBorder: Color.lerp(floatingBorder, other.floatingBorder, t)!,
      floatingShadow: Color.lerp(floatingShadow, other.floatingShadow, t)!,
      activePill: Color.lerp(activePill, other.activePill, t)!,
      onActivePill: Color.lerp(onActivePill, other.onActivePill, t)!,
      inactiveIcon: Color.lerp(inactiveIcon, other.inactiveIcon, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight: Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
    );
  }
}

extension PremiumThemeContext on BuildContext {
  PremiumTokens get premium =>
      Theme.of(this).extension<PremiumTokens>() ?? PremiumTokens.fromScheme(Theme.of(this).colorScheme);
}
