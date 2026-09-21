import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color bgDark = Color(0xFF090C15);
  static const Color bgSurface = Color(0xFF0E1322);
  static const Color bgCard = Color(0xFF141A2D);
  static const Color bgCardAlt = Color(0xFF192138);
  static const Color bgCardHighlight = Color(0xFF1E2845);

  // Borders
  static const Color borderSubtle = Color(0x1FFFFFFF);
  static const Color borderCard = Color(0x18FFFFFF);
  static const Color borderGlow = Color(0x3D8B5CF6);

  // Accents
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF7C3AED);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentPink = Color(0xFFEC4899);

  // Semantics
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0x28EF4444);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x268B5CF6), Color(0x05141A2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGlowGradient = LinearGradient(
    colors: [Color(0x33F97316), Color(0x05141A2D)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.bgSurface,
        background: AppColors.bgDark,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
