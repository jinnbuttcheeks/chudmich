import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Material weight of a glass surface.
enum GlassVariant {
  /// Chips, small buttons, badges.
  thin,

  /// Bars, cards, menus.
  regular,

  /// Sheets and dialogs.
  thick,

  /// Active-tab lens: barely blurs, brightens and saturates what is under it.
  lens,
}

/// Numeric recipe for one [GlassVariant] in one brightness.
@immutable
class GlassSpec {
  const GlassSpec({
    required this.sigma,
    required this.tintAlpha,
    required this.saturation,
    required this.brightness,
    required this.rimAlpha,
    required this.glowAlpha,
    required this.shadowAlpha,
    required this.shadowBlur,
    required this.fallbackTintAlpha,
  });

  /// Gaussian blur sigma of the backdrop.
  final double sigma;

  /// Opacity of the theme tint laid over the blurred backdrop.
  final double tintAlpha;

  /// Backdrop saturation multiplier (1 = unchanged); >1 makes content behind vivid.
  final double saturation;

  /// Backdrop brightness offset in the range of a colour matrix (-1..1).
  final double brightness;

  /// Peak opacity of the specular rim.
  final double rimAlpha;

  /// Opacity of the inner top-left glow.
  final double glowAlpha;

  final double shadowAlpha;
  final double shadowBlur;

  /// Tint opacity used when the surface falls back to fake glass (no backdrop filter).
  final double fallbackTintAlpha;

  static GlassSpec of(GlassVariant variant, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (variant) {
      case GlassVariant.thin:
        return GlassSpec(
          sigma: 18,
          tintAlpha: dark ? 0.30 : 0.38,
          saturation: 1.6,
          brightness: dark ? 0.02 : 0.05,
          rimAlpha: dark ? 0.55 : 0.85,
          glowAlpha: dark ? 0.10 : 0.30,
          shadowAlpha: dark ? 0.28 : 0.10,
          shadowBlur: 14,
          fallbackTintAlpha: dark ? 0.72 : 0.80,
        );
      case GlassVariant.regular:
        return GlassSpec(
          sigma: 24,
          tintAlpha: dark ? 0.42 : 0.52,
          saturation: 1.8,
          brightness: dark ? 0.03 : 0.06,
          rimAlpha: dark ? 0.60 : 0.90,
          glowAlpha: dark ? 0.12 : 0.34,
          shadowAlpha: dark ? 0.42 : 0.16,
          shadowBlur: 28,
          fallbackTintAlpha: dark ? 0.82 : 0.88,
        );
      case GlassVariant.lens:
        return GlassSpec(
          sigma: 2.5,
          tintAlpha: dark ? 0.26 : 0.30,
          saturation: 1.5,
          brightness: dark ? 0.09 : 0.10,
          rimAlpha: dark ? 0.80 : 0.95,
          glowAlpha: dark ? 0.22 : 0.40,
          shadowAlpha: dark ? 0.30 : 0.10,
          shadowBlur: 12,
          fallbackTintAlpha: dark ? 0.50 : 0.60,
        );
      case GlassVariant.thick:
        return GlassSpec(
          sigma: 30,
          tintAlpha: dark ? 0.58 : 0.66,
          saturation: 1.9,
          brightness: dark ? 0.03 : 0.06,
          rimAlpha: dark ? 0.65 : 0.95,
          glowAlpha: dark ? 0.14 : 0.38,
          shadowAlpha: dark ? 0.55 : 0.22,
          shadowBlur: 40,
          fallbackTintAlpha: dark ? 0.92 : 0.94,
        );
    }
  }
}

abstract final class GlassMath {
  /// 4x5 colour matrix boosting saturation by [saturation] and shifting
  /// brightness by [brightness]. Applied to the blurred backdrop so photos
  /// and gradients behind the glass look vivid instead of washed out.
  static List<double> saturationMatrix(double saturation, {double brightness = 0}) {
    const lumR = 0.2126;
    const lumG = 0.7152;
    const lumB = 0.0722;
    final s = saturation;
    final inv = 1 - s;
    final b = brightness * 255;
    return <double>[
      lumR * inv + s, lumG * inv, lumB * inv, 0, b, //
      lumR * inv, lumG * inv + s, lumB * inv, 0, b,
      lumR * inv, lumG * inv, lumB * inv + s, 0, b,
      0, 0, 0, 1, 0,
    ];
  }

  static final Map<(double, double, double), ui.ImageFilter> _filters = <(double, double, double), ui.ImageFilter>{};

  /// Backdrop filter: blur followed by the saturation boost, as one layer.
  ///
  /// Filters are immutable, so one instance per recipe is shared by every
  /// surface: no native filter objects are allocated per build and the engine
  /// sees an identical filter between frames.
  static ui.ImageFilter backdropFilter(GlassSpec spec) {
    return _filters.putIfAbsent(
      (spec.sigma, spec.saturation, spec.brightness),
      () => ui.ImageFilter.compose(
        outer: ui.ColorFilter.matrix(saturationMatrix(spec.saturation, brightness: spec.brightness)),
        inner: ui.ImageFilter.blur(sigmaX: spec.sigma, sigmaY: spec.sigma, tileMode: TileMode.mirror),
      ),
    );
  }

  /// Number of distinct cached backdrop filters. Test hook.
  @visibleForTesting
  static int get cachedFilterCount => _filters.length;

  /// Smallest light movement that is published to listening surfaces.
  static const double lightStep = 0.015;

  /// Light direction used when nothing moves: up and to the left.
  static const Offset restingLight = Offset(-0.7, -0.7);

  /// Maps a scroll offset (logical px) to a light direction in -1..1 space.
  ///
  /// One full sweep of the light takes [pixelsPerSweep] of scrolling, and the
  /// movement stays within a gentle arc so the highlight never flips sides.
  static Offset lightFromScroll(double offset, {double pixelsPerSweep = 2400}) {
    final phase = offset / pixelsPerSweep * 2 * math.pi;
    final x = restingLight.dx + 0.55 * math.sin(phase);
    final y = restingLight.dy + 0.25 * math.cos(phase) - 0.25;
    return Offset(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0));
  }

  /// Maps a fractional tab position to a light direction (light follows the active tab).
  static Offset lightFromTab(double position, int count) {
    if (count <= 1) {
      return restingLight;
    }
    final t = (position / (count - 1)).clamp(0.0, 1.0);
    return Offset(-0.9 + 1.8 * t, restingLight.dy);
  }

  /// Maps a drag position (0..1 across the surface) to a light direction.
  static Offset lightFromPointer(Offset normalized) {
    return Offset((normalized.dx * 2 - 1).clamp(-1.0, 1.0), (normalized.dy * 2 - 1).clamp(-1.0, 1.0));
  }

  /// Rim gradient endpoints for a [light] direction: the bright end sits
  /// where the light comes from, the opposite corner gets a faint secondary glint.
  static ({Alignment begin, Alignment end}) rimAlignment(Offset light) {
    final dir = Alignment(light.dx.clamp(-1.0, 1.0), light.dy.clamp(-1.0, 1.0));
    return (begin: dir, end: Alignment(-dir.x, -dir.y));
  }

  /// Opacity multiplier of the rim's far-side glint (always faint).
  static const double farGlint = 0.28;
}

/// Counts live backdrop-blurring glass layers so the app stays inside its
/// performance budget. Surfaces that cannot acquire a slot render as fake
/// glass (static gradients) instead of a [BackdropFilter].
class GlassLayerBudget {
  GlassLayerBudget({this.max = 4});

  /// Shared by every glass surface in the app.
  static final GlassLayerBudget shared = GlassLayerBudget();

  /// Maximum simultaneously blurring layers.
  final int max;

  final Set<Object> _owners = <Object>{};

  int get active => _owners.length;

  /// Tries to take a slot for [owner]. Re-acquiring is idempotent.
  /// [essential] owners (sheets, dialogs) always succeed.
  bool tryAcquire(Object owner, {bool essential = false}) {
    if (_owners.contains(owner)) {
      return true;
    }
    if (!essential && _owners.length >= max) {
      return false;
    }
    _owners.add(owner);
    return true;
  }

  void release(Object owner) => _owners.remove(owner);

  void reset() => _owners.clear();
}
