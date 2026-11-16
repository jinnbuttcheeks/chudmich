import 'package:flutter/material.dart';

import 'package:immich_mobile/constants/locales.dart';
import 'package:immich_mobile/extensions/theme_extensions.dart';
import 'package:immich_mobile/theme/premium_tokens.dart';
import 'package:immich_mobile/theme/solid/solid_tokens.dart';

class ImmichTheme {
  final ColorScheme light;
  final ColorScheme dark;

  const ImmichTheme({required this.light, required this.dark});
}

ThemeData getThemeData({required ColorScheme colorScheme, required Locale locale}) {
  final isDark = colorScheme.brightness == Brightness.dark;
  final solid = SolidTokens.fromScheme(colorScheme);
  final font = _getFontFamilyFromLocale(locale);
  final border = solid.hairline;
  const fieldRadius = BorderRadius.all(Radius.circular(SolidTokens.radius));
  const cardRadius = BorderRadius.all(Radius.circular(SolidTokens.radiusCard));

  return ThemeData(
    useMaterial3: true,
    extensions: [PremiumTokens.fromScheme(colorScheme), solid],
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    primaryColor: colorScheme.primary,
    hintColor: colorScheme.onSurfaceSecondary,
    focusColor: colorScheme.primary,
    scaffoldBackgroundColor: solid.canvas,
    splashColor: solid.subtleHover,
    highlightColor: solid.subtle,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: solid.paper,
      modalBackgroundColor: solid.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SolidTokens.radiusSheet)),
        side: border,
      ),
    ),
    fontFamily: font,
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: TextStyle(fontFamily: font, color: solid.inkStrong, fontWeight: FontWeight.w600),
      backgroundColor: solid.paper,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: cardRadius, side: border),
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: TextStyle(
        color: solid.inkStrong,
        fontFamily: font,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        letterSpacing: -0.3,
      ),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: solid.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    // AIOStreams type scale: tight tracking, heavy headings, medium weight labels.
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      displayMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      displaySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, letterSpacing: -0.1),
      titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, letterSpacing: -0.35),
      titleLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700, letterSpacing: -0.9),
      headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600, letterSpacing: -0.6),
      headlineMedium: TextStyle(fontSize: 30.0, fontWeight: FontWeight.w700, letterSpacing: -0.9),
      headlineLarge: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w800, letterSpacing: -1.2),
      labelLarge: TextStyle(fontWeight: FontWeight.w500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: solid.accentFill,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: fieldRadius,
          side: BorderSide(color: solid.accentBorder),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: fieldRadius),
        padding: const EdgeInsets.symmetric(horizontal: 22),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: fieldRadius),
        side: border,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: fieldRadius)),
    ),
    chipTheme: ChipThemeData(side: border, shape: const StadiumBorder(), backgroundColor: solid.panel),
    sliderTheme: const SliderThemeData(
      trackHeight: 12,
      // ignore: deprecated_member_use
      year2023: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(type: BottomNavigationBarType.fixed),
    popupMenuTheme: PopupMenuThemeData(
      color: solid.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: cardRadius, side: border),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: solid.paper,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 14, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: solid.panel,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isDark ? AioPalette.brand200 : colorScheme.primary, width: 1.4),
        borderRadius: fieldRadius,
      ),
      enabledBorder: OutlineInputBorder(borderSide: border, borderRadius: fieldRadius),
      labelStyle: TextStyle(color: colorScheme.primary),
      hintStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: colorScheme.primary),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: const MenuStyle(
        shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(borderRadius: fieldRadius)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.primary)),
        enabledBorder: OutlineInputBorder(borderSide: border, borderRadius: fieldRadius),
        labelStyle: TextStyle(color: colorScheme.primary),
        hintStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: solid.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: cardRadius, side: border),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: solid.subtleHover,
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
      surface: AioPalette.lightBackground,
      onSurface: AioPalette.gray800,
      surfaceContainerLowest: AioPalette.lightPaper,
      surfaceContainerLow: AioPalette.lightPanel,
      surfaceContainer: AioPalette.lightRaised,
      surfaceContainerHigh: const Color(0xFFe8e8e8),
      surfaceContainerHighest: const Color(0xFFe2e2e2),
      surfaceDim: const Color(0xFFdadada),
      surfaceBright: const Color(0xFFf9f9f9),
      onSurfaceVariant: const Color(0xFF4c4546),
      inverseSurface: const Color(0xFF303030),
      onInverseSurface: const Color(0xFFf1f1f1),
    ),
    dark: theme.dark.copyWith(
      surface: AioPalette.background,
      onSurface: AioPalette.gray200,
      surfaceContainerLowest: AioPalette.background,
      surfaceContainerLow: AioPalette.gray950,
      surfaceContainer: AioPalette.gray900,
      surfaceContainerHigh: AioPalette.gray800,
      surfaceContainerHighest: const Color(0xFF262626),
      surfaceDim: AioPalette.background,
      surfaceBright: const Color(0xFF303030),
      onSurfaceVariant: AioPalette.gray400,
      inverseSurface: AioPalette.gray200,
      onInverseSurface: AioPalette.gray900,
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
