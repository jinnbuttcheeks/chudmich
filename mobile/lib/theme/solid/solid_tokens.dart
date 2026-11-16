import 'package:flutter/material.dart';

/// Raw palette of the solid design, taken from the AIOStreams web UI
/// (https://github.com/Viren070/AIOStreams, `packages/ui/theme.css`).
abstract final class AioPalette {
  static const Color background = Color(0xFF070707);
  static const Color gray950 = Color(0xFF0B0B0B);
  static const Color gray900 = Color(0xFF101010);
  static const Color gray800 = Color(0xFF1C1C1C);
  static const Color gray400 = Color(0xFF8F8F8F);
  static const Color gray200 = Color(0xFFD1D1D1);

  static const Color brand200 = Color(0xFFD4D0FF);
  static const Color brand300 = Color(0xFFC7C2FF);
  static const Color brand400 = Color(0xFF9F92FF);
  static const Color brand500 = Color(0xFF6152DF);
  static const Color brand600 = Color(0xFF5243CB);
  static const Color brand700 = Color(0xFF3F2EB2);

  // Light mode: white page, gray-800 text, gray-200 borders.
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightPaper = Color(0xFFFFFFFF);
  static const Color lightPanel = Color(0xFFF5F5F5);
  static const Color lightRaised = Color(0xFFEBEBEB);
  static const Color lightBorder = Color(0xFFE5E5E5);
}

/// Solid design tokens: flat surfaces, hairline borders, one accent. Derived from the active
/// [ColorScheme], so the primary color setting, dynamic color and light/dark keep working. The
/// default (non colorful) scheme resolves to the AIOStreams palette.
@immutable
class SolidTokens extends ThemeExtension<SolidTokens> {
  const SolidTokens({
    required this.brightness,
    required this.canvas,
    required this.paper,
    required this.panel,
    required this.raised,
    required this.ink,
    required this.inkStrong,
    required this.muted,
    required this.mutedStrong,
    required this.inactive,
    required this.border,
    required this.subtle,
    required this.subtleHover,
    required this.accent,
    required this.onAccent,
    required this.accentFill,
    required this.accentBorder,
  });

  /// Controls that float over photos and video, in light and dark mode alike. Solid, no blur.
  static const Color overPhoto = Color(0xB8101010);

  /// Scrim stops for top and bottom bars over media.
  static const List<Color> scrim = [Color(0x99000000), Color(0x33000000), Color(0x00000000)];

  // Radii (AIOStreams: 0.5rem base, rounded-xl cards, rounded-full pills).
  static const double radius = 8;
  static const double radiusCard = 12;
  static const double radiusSheet = 20;
  static const double radiusPill = 999;

  // Motion (AIOStreams: 200 ms ease-out slides, 100 ms fade-outs, emphasized decelerate for shared elements).
  static const Duration durationFast = Duration(milliseconds: 100);
  static const Duration duration = Duration(milliseconds: 200);
  static const Duration durationEmphasized = Duration(milliseconds: 450);
  static const Curve curve = Curves.easeOut;
  static const Curve curveEmphasized = Cubic(0.05, 0.7, 0.1, 1);

  /// `0 12px 32px -12px rgb(0 0 0 / 0.7)`: floating bars, sheets and toasts.
  static const List<BoxShadow> floatingShadow = [
    BoxShadow(color: Color(0xB3000000), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -12),
  ];

  /// Tailwind `shadow-sm`, for cards.
  static const List<BoxShadow> cardShadow = [BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2)];

  final Brightness brightness;

  /// Page background.
  final Color canvas;

  /// Cards and bars (gray-950 in dark).
  final Color paper;

  /// Deeper panels, inputs and pill tracks (gray-900).
  final Color panel;

  /// Raised fills (gray-800).
  final Color raised;

  /// Body text (gray-200) and emphasized text (white).
  final Color ink;
  final Color inkStrong;

  /// Muted text (white at 40%) and its highlighted variant (60%).
  final Color muted;
  final Color mutedStrong;

  /// Inactive navigation text (gray-400).
  final Color inactive;

  /// Hairline border (white at 10%).
  final Color border;

  /// Subtle fill (white at 6%) and its hover/pressed state (8%).
  final Color subtle;
  final Color subtleHover;

  final Color accent;
  final Color onAccent;

  /// Primary button fill (accent at about 70%) and its border (lighter accent at 20%).
  final Color accentFill;
  final Color accentBorder;

  bool get isDark => brightness == Brightness.dark;

  /// `1px` hairline used by every surface.
  BorderSide get hairline => BorderSide(color: border);

  factory SolidTokens.fromScheme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final onSurface = scheme.onSurface;
    final primary = scheme.primary;
    // The default violet scheme keeps brand-400 for text and icons, but fills buttons with brand-500.
    final fill = primary == AioPalette.brand400 ? AioPalette.brand500 : primary;
    final lightAccent = Color.lerp(primary, Colors.white, 0.35)!;
    return SolidTokens(
      brightness: scheme.brightness,
      canvas: scheme.surface,
      paper: dark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
      panel: dark ? scheme.surfaceContainer : scheme.surfaceContainerLow,
      raised: dark ? scheme.surfaceContainerHigh : scheme.surfaceContainer,
      ink: dark ? onSurface : onSurface,
      inkStrong: dark ? Colors.white : Colors.black,
      muted: onSurface.withValues(alpha: dark ? 0.40 : 0.50),
      mutedStrong: onSurface.withValues(alpha: dark ? 0.60 : 0.70),
      inactive: scheme.onSurfaceVariant,
      border: dark ? Colors.white.withValues(alpha: 0.10) : AioPalette.lightBorder,
      subtle: dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
      subtleHover: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
      accent: primary,
      onAccent: scheme.onPrimary,
      accentFill: dark ? fill.withValues(alpha: 0.7) : primary,
      accentBorder: dark ? lightAccent.withValues(alpha: 0.2) : Colors.transparent,
    );
  }

  @override
  SolidTokens copyWith({Color? canvas, Color? paper, Color? accent}) {
    return SolidTokens(
      brightness: brightness,
      canvas: canvas ?? this.canvas,
      paper: paper ?? this.paper,
      panel: panel,
      raised: raised,
      ink: ink,
      inkStrong: inkStrong,
      muted: muted,
      mutedStrong: mutedStrong,
      inactive: inactive,
      border: border,
      subtle: subtle,
      subtleHover: subtleHover,
      accent: accent ?? this.accent,
      onAccent: onAccent,
      accentFill: accentFill,
      accentBorder: accentBorder,
    );
  }

  @override
  SolidTokens lerp(ThemeExtension<SolidTokens>? other, double t) {
    if (other is! SolidTokens) {
      return this;
    }
    return SolidTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkStrong: Color.lerp(inkStrong, other.inkStrong, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedStrong: Color.lerp(mutedStrong, other.mutedStrong, t)!,
      inactive: Color.lerp(inactive, other.inactive, t)!,
      border: Color.lerp(border, other.border, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      subtleHover: Color.lerp(subtleHover, other.subtleHover, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentFill: Color.lerp(accentFill, other.accentFill, t)!,
      accentBorder: Color.lerp(accentBorder, other.accentBorder, t)!,
    );
  }
}

extension SolidThemeContext on BuildContext {
  SolidTokens get solid =>
      Theme.of(this).extension<SolidTokens>() ?? SolidTokens.fromScheme(Theme.of(this).colorScheme);
}
