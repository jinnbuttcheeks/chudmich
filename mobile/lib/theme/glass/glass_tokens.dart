import 'package:flutter/material.dart';

/// Colours of the liquid glass material, derived from the active [ColorScheme]
/// so dynamic colour, the primary colour setting and light/dark mode keep working.
@immutable
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.brightness,
    required this.tint,
    required this.highlight,
    required this.ink,
    required this.inkSecondary,
    required this.accent,
    required this.canvas,
    required this.canvasDeep,
    required this.blobA,
    required this.blobB,
    required this.blobC,
  });

  final Brightness brightness;

  /// Translucent body colour of the glass.
  final Color tint;

  /// Colour of rim and glow (white-ish).
  final Color highlight;

  /// Foreground colour on glass.
  final Color ink;
  final Color inkSecondary;
  final Color accent;

  /// Base of the ambient background, and its deeper edge.
  final Color canvas;
  final Color canvasDeep;

  /// Ambient blob colours.
  final Color blobA;
  final Color blobB;
  final Color blobC;

  bool get isDark => brightness == Brightness.dark;

  factory GlassTokens.fromScheme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final primary = scheme.primary;
    final hsl = HSLColor.fromColor(primary);
    Color shifted(double degrees, {double? saturation, double? lightness}) => hsl
        .withHue((hsl.hue + degrees) % 360)
        .withSaturation(saturation ?? hsl.saturation.clamp(0.45, 0.9))
        .withLightness(lightness ?? hsl.lightness)
        .toColor();

    // Deep ink for dark mode, soft porcelain for light; both carry a trace of the primary colour.
    final canvas = dark
        ? Color.alphaBlend(primary.withValues(alpha: 0.06), const Color(0xFF07080C))
        : Color.alphaBlend(primary.withValues(alpha: 0.05), const Color(0xFFF4F5F9));
    final deep = dark
        ? Color.alphaBlend(primary.withValues(alpha: 0.10), const Color(0xFF020306))
        : Color.alphaBlend(primary.withValues(alpha: 0.10), const Color(0xFFE6E8F0));

    return GlassTokens(
      brightness: scheme.brightness,
      tint: dark ? const Color(0xFF14161F) : const Color(0xFFFFFFFF),
      highlight: Colors.white,
      ink: dark ? const Color(0xFFF4F5FA) : const Color(0xFF12131A),
      inkSecondary: dark ? const Color(0xFFB4B7C6) : const Color(0xFF555969),
      accent: primary,
      canvas: canvas,
      canvasDeep: deep,
      blobA: primary.withValues(alpha: dark ? 0.55 : 0.38),
      blobB: shifted(48, lightness: dark ? 0.5 : 0.62).withValues(alpha: dark ? 0.40 : 0.32),
      blobC: shifted(-62, lightness: dark ? 0.46 : 0.66).withValues(alpha: dark ? 0.36 : 0.30),
    );
  }

  @override
  GlassTokens copyWith({
    Brightness? brightness,
    Color? tint,
    Color? highlight,
    Color? ink,
    Color? inkSecondary,
    Color? accent,
    Color? canvas,
    Color? canvasDeep,
    Color? blobA,
    Color? blobB,
    Color? blobC,
  }) {
    return GlassTokens(
      brightness: brightness ?? this.brightness,
      tint: tint ?? this.tint,
      highlight: highlight ?? this.highlight,
      ink: ink ?? this.ink,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      accent: accent ?? this.accent,
      canvas: canvas ?? this.canvas,
      canvasDeep: canvasDeep ?? this.canvasDeep,
      blobA: blobA ?? this.blobA,
      blobB: blobB ?? this.blobB,
      blobC: blobC ?? this.blobC,
    );
  }

  @override
  GlassTokens lerp(ThemeExtension<GlassTokens>? other, double t) {
    if (other is! GlassTokens) {
      return this;
    }
    return GlassTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      tint: Color.lerp(tint, other.tint, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      canvasDeep: Color.lerp(canvasDeep, other.canvasDeep, t)!,
      blobA: Color.lerp(blobA, other.blobA, t)!,
      blobB: Color.lerp(blobB, other.blobB, t)!,
      blobC: Color.lerp(blobC, other.blobC, t)!,
    );
  }
}

extension GlassThemeContext on BuildContext {
  GlassTokens get glass =>
      Theme.of(this).extension<GlassTokens>() ?? GlassTokens.fromScheme(Theme.of(this).colorScheme);
}
