import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color palette - cinematic dark TV theme
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF141927);
  static const Color surfaceElevated = Color(0xFF1E2638);
  static const Color primary = Color(0xFF4F8EF7);
  static const Color primaryVariant = Color(0xFF2563EB);
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentSecondary = Color(0xFF7C3AED);
  static const Color onBackground = Color(0xFFE8ECF0);
  static const Color onSurface = Color(0xFFB0BBC8);
  static const Color focused = Color(0xFF4F8EF7);
  static const Color focusedBorder = Color(0xFF7AB3FF);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color divider = Color(0xFF2A3347);
  static const Color cardBackground = Color(0xFF171E2E);
  static const Color shimmerBase = Color(0xFF1E2638);
  static const Color shimmerHighlight = Color(0xFF2A3550);

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        background: background,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onBackground,
        onBackground: onBackground,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: onBackground,
        displayColor: onBackground,
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      focusColor: focused.withOpacity(0.15),
      hoverColor: focused.withOpacity(0.08),
      highlightColor: focused.withOpacity(0.12),
      splashColor: focused.withOpacity(0.15),
      dividerColor: divider,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: focusedBorder, width: 2),
        ),
        hintStyle: const TextStyle(color: onSurface),
        labelStyle: const TextStyle(color: onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      iconTheme: const IconThemeData(
        color: onSurface,
        size: 24,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }
}

// TV-specific text styles
class TVTextStyles {
  static const TextStyle headline = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppTheme.onBackground,
    letterSpacing: -0.5,
  );

  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppTheme.onBackground,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppTheme.onSurface,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppTheme.onBackground,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppTheme.onSurface,
  );

  static const TextStyle channelName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.onBackground,
  );

  static const TextStyle categoryTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppTheme.onBackground,
    letterSpacing: 0.2,
  );
}
