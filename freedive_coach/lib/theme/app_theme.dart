import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Base colors from design.pen
  static const Color bg = Color(0xFF03141D);
  static const Color coral = Color(0xFFFF8D6B);
  static const Color deep = Color(0xFF082534);
  static const Color line = Color(0xFF1A5A6A);
  static const Color muted = Color(0xFF84A8B2);
  static const Color primary = Color(0xFF4FE0CC);
  static const Color primaryBright = Color(0xFF9DE5E0);
  static const Color surface = Color(0xFF0D3547);
  static const Color surface2 = Color(0xFF103A4D);
  static const Color tealDim = Color(0xFF2A9D8F);
  static const Color text = Color(0xFFE8F5F6);

  // Additional colors
  static const Color amber = Color(0xFFFFCE6B);
  static const Color mint = Color(0xFFA8E6CF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;
}

class AppRadius {
  static const double standard = 16.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 20.0;
  static const double pill = 28.0;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryBright,
        surface: AppColors.surface,
        error: AppColors.coral,
      ),
      textTheme: GoogleFonts.notoSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: AppColors.text),
          displayMedium: TextStyle(color: AppColors.text),
          displaySmall: TextStyle(color: AppColors.text),
          headlineLarge: TextStyle(color: AppColors.text),
          headlineMedium: TextStyle(color: AppColors.text),
          headlineSmall: TextStyle(color: AppColors.text),
          titleLarge: TextStyle(color: AppColors.text),
          titleMedium: TextStyle(color: AppColors.text),
          titleSmall: TextStyle(color: AppColors.text),
          bodyLarge: TextStyle(color: AppColors.text),
          bodyMedium: TextStyle(color: AppColors.text),
          bodySmall: TextStyle(color: AppColors.muted),
          labelLarge: TextStyle(color: AppColors.text),
          labelMedium: TextStyle(color: AppColors.text),
          labelSmall: TextStyle(color: AppColors.muted),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryBright,
        unselectedItemColor: AppColors.muted,
      ),
    );
  }
}

class AppTextStyles {
  static TextStyle get titleLarge => GoogleFonts.notoSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      );

  static TextStyle get titleMedium => GoogleFonts.notoSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      );

  static TextStyle get titleSmall => GoogleFonts.notoSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      );

  static TextStyle get sectionTitle => GoogleFonts.notoSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      );

  static TextStyle get body => GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.text,
      );

  static TextStyle get bodySmall => GoogleFonts.notoSans(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: AppColors.text,
      );

  static TextStyle get caption => GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.muted,
      );

  static TextStyle get label => GoogleFonts.notoSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
      );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: AppColors.text,
      );

  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.muted,
      );
}
