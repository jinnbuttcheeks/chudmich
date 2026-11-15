import 'package:flutter/material.dart';

import 'package:immich_mobile/constants/locales.dart';
import 'package:immich_mobile/extensions/theme_extensions.dart';
import 'package:immich_mobile/theme/glass/glass_tokens.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';

class ImmichTheme {
  final ColorScheme light;
  final ColorScheme dark;

  const ImmichTheme({required this.light, required this.dark});
}

ThemeData getThemeData({required ColorScheme colorScheme, required Locale locale}) {
  final isDark = colorScheme.brightness == Brightness.dark;
  final glass = GlassTokens.fromScheme(colorScheme);
  final rim = BorderSide(color: glass.highlight.withValues(alpha: isDark ? 0.16 : 0.7), width: 0.8);

  return ThemeData(
    useMaterial3: true,
    extensions: [PremiumTokens.fromScheme(colorScheme), glass],
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    primaryColor: colorScheme.primary,
    hintColor: colorScheme.onSurfaceSecondary,
    focusColor: colorScheme.primary,
    scaffoldBackgroundColor: glass.canvas,
    splashColor: colorScheme.primary.withValues(alpha: 0.1),
    highlightColor: colorScheme.primary.withValues(alpha: 0.1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: glass.tint.withValues(alpha: isDark ? 0.90 : 0.92),
      modalBackgroundColor: glass.tint.withValues(alpha: isDark ? 0.90 : 0.92),
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: RoundedSuperellipseBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(PremiumTokens.radiusSheet + 6)),
        side: rim,
      ),
    ),
    fontFamily: _getFontFamilyFromLocale(locale),
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: TextStyle(
        fontFamily: _getFontFamilyFromLocale(locale),
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: glass.tint.withValues(alpha: isDark ? 0.94 : 0.96),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(20), side: rim),
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: TextStyle(
        color: colorScheme.primary,
        fontFamily: _getFontFamilyFromLocale(locale),
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colorScheme.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    // Slightly tightened tracking on larger sizes keeps headings crisp.
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      displayMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      displaySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, letterSpacing: -0.1),
      titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, letterSpacing: -0.35),
      titleLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700, letterSpacing: -0.9),
      headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700, letterSpacing: -0.7),
      headlineMedium: TextStyle(fontSize: 30.0, fontWeight: FontWeight.w700, letterSpacing: -0.9),
      headlineLarge: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w800, letterSpacing: -1.2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: isDark ? Colors.black87 : Colors.white,
        shape: const StadiumBorder(),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 22)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: const StadiumBorder(), side: rim),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: const StadiumBorder())),
    chipTheme: ChipThemeData(
      side: rim,
      shape: const StadiumBorder(),
      backgroundColor: glass.tint.withValues(alpha: 0.5),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 12,
      // ignore: deprecated_member_use
      year2023: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(type: BottomNavigationBarType.fixed),
    popupMenuTheme: PopupMenuThemeData(
      color: glass.tint.withValues(alpha: isDark ? 0.92 : 0.94),
      surfaceTintColor: Colors.transparent,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(18), side: rim),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 14, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glass.tint.withValues(alpha: isDark ? 0.55 : 0.6),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        borderRadius: const BorderRadius.all(Radius.circular(18)),
      ),
      enabledBorder: OutlineInputBorder(borderSide: rim, borderRadius: const BorderRadius.all(Radius.circular(18))),
      labelStyle: TextStyle(color: colorScheme.primary),
      hintStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: colorScheme.primary),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: const MenuStyle(
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.primary)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outlineVariant),
          borderRadius: const BorderRadius.all(Radius.circular(15)),
        ),
        labelStyle: TextStyle(color: colorScheme.primary),
        hintStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: glass.tint.withValues(alpha: isDark ? 0.94 : 0.96),
      surfaceTintColor: Colors.transparent,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(PremiumTokens.radiusLg + 4), side: rim),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.16),
      indicatorShape: const StadiumBorder(),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      // ignore: deprecated_member_use
      year2023: false,
      // TODO: Uncommented after upgrade to version later than 3.29.2
      // circularTrackColor: Colors.black12,
      trackGap: 3,
    ),
  );
}

// This method replaces all surface shades in ImmichTheme to a static ones
// as we are creating the colorscheme through seedColor the default surfaces are
// tinted with primary color
ImmichTheme decolorizeSurfaces({required ImmichTheme theme}) {
  return ImmichTheme(
    light: theme.light.copyWith(
      surface: const Color(0xFFF4F5F9),
      onSurface: const Color(0xFF14151C),
      surfaceContainerLowest: const Color(0xFFffffff),
      surfaceContainerLow: const Color(0xFFf3f3f3),
      surfaceContainer: const Color(0xFFeeeeee),
      surfaceContainerHigh: const Color(0xFFe8e8e8),
      surfaceContainerHighest: const Color(0xFFe2e2e2),
      surfaceDim: const Color(0xFFdadada),
      surfaceBright: const Color(0xFFf9f9f9),
      onSurfaceVariant: const Color(0xFF4c4546),
      inverseSurface: const Color(0xFF303030),
      onInverseSurface: const Color(0xFFf1f1f1),
    ),
    dark: theme.dark.copyWith(
      surface: const Color(0xFF090A0F),
      onSurface: const Color(0xFFE9EAF2),
      surfaceContainerLowest: const Color(0xFF05060A),
      surfaceContainerLow: const Color(0xFF0F1118),
      surfaceContainer: const Color(0xFF141621),
      surfaceContainerHigh: const Color(0xFF1B1E2B),
      surfaceContainerHighest: const Color(0xFF242837),
      surfaceDim: const Color(0xFF090A0F),
      surfaceBright: const Color(0xFF2E3243),
      onSurfaceVariant: const Color(0xFFC3C6D6),
      inverseSurface: const Color(0xFFE9EAF2),
      onInverseSurface: const Color(0xFF2A2C38),
    ),
  );
}

String? _getFontFamilyFromLocale(Locale locale) {
  if (localesNotSupportedByAppFont.contains(locale)) {
    // Let Flutter use the default font
    return null;
  }
  return 'GoogleSans';
}
