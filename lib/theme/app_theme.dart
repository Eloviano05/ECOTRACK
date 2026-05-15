import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EcoColors {
  // Primary greens
  static const primary = Color(0xFF006E1C);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF4CAF50);
  static const onPrimaryContainer = Color(0xFF003C0B);
  static const primaryFixed = Color(0xFF94F990);
  static const primaryFixedDim = Color(0xFF78DC77);
  static const onPrimaryFixedVariant = Color(0xFF005313);
  static const inversePrimary = Color(0xFF78DC77);

  // Secondary greens
  static const secondary = Color(0xFF42673F);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFC3EEBB);
  static const onSecondaryContainer = Color(0xFF486D45);
  static const secondaryFixed = Color(0xFFC3EEBB);
  static const secondaryFixedDim = Color(0xFFA8D1A1);

  // Tertiary pink
  static const tertiary = Color(0xFFA63360);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFF26F9D);

  // Surface
  static const surface = Color(0xFFF5FBEF);
  static const surfaceVariant = Color(0xFFDEE4D9);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF0F6EA);
  static const surfaceContainer = Color(0xFFEAF0E4);
  static const surfaceContainerHigh = Color(0xFFE4EADE);
  static const surfaceContainerHighest = Color(0xFFDEE4D9);
  static const surfaceDim = Color(0xFFD6DCD0);
  static const surfaceBright = Color(0xFFF5FBEF);
  static const inverseSurface = Color(0xFF2C322A);
  static const inverseOnSurface = Color(0xFFEDF3E7);

  // On-surface
  static const background = Color(0xFFF5FBEF);
  static const onBackground = Color(0xFF171D16);
  static const onSurface = Color(0xFF171D16);
  static const onSurfaceVariant = Color(0xFF3F4A3C);

  // Outline
  static const outline = Color(0xFF6F7A6B);
  static const outlineVariant = Color(0xFFBECAB9);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: EcoColors.primary,
        onPrimary: EcoColors.onPrimary,
        primaryContainer: EcoColors.primaryContainer,
        onPrimaryContainer: EcoColors.onPrimaryContainer,
        secondary: EcoColors.secondary,
        onSecondary: EcoColors.onSecondary,
        secondaryContainer: EcoColors.secondaryContainer,
        onSecondaryContainer: EcoColors.onSecondaryContainer,
        tertiary: EcoColors.tertiary,
        onTertiary: EcoColors.onTertiary,
        tertiaryContainer: EcoColors.tertiaryContainer,
        onTertiaryContainer: Color(0xFF690034),
        error: EcoColors.error,
        onError: EcoColors.onError,
        errorContainer: EcoColors.errorContainer,
        onErrorContainer: Color(0xFF93000A),
        surface: EcoColors.surface,
        onSurface: EcoColors.onSurface,
        onSurfaceVariant: EcoColors.onSurfaceVariant,
        outline: EcoColors.outline,
        outlineVariant: EcoColors.outlineVariant,
        inverseSurface: EcoColors.inverseSurface,
        onInverseSurface: EcoColors.inverseOnSurface,
        inversePrimary: EcoColors.inversePrimary,
      ),
      scaffoldBackgroundColor: EcoColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: EcoColors.surface,
        elevation: 1,
        shadowColor: Colors.black12,
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: EcoColors.primary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: EcoColors.surface,
        selectedItemColor: EcoColors.primary,
        unselectedItemColor: EcoColors.onSurfaceVariant,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EcoColors.primary,
          foregroundColor: EcoColors.onPrimary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
