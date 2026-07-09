import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color bg = Color(0xFF05090F);
  static const Color coral = Color(0xFFFF7B72);
  static const Color deep = Color(0xFF0A2E4F);
  static const Color line = Color(0xFF1C2B3A);
  static const Color muted = Color(0xFF64808F);
  static const Color primary = Color(0xFF2F86D6);
  static const Color primaryBright = Color(0xFF5EB6F7);
  static const Color surface = Color(0xFF0C141D);
  static const Color surface2 = Color(0xFF142230);
  static const Color tealDim = Color(0xFF0E2438);
  static const Color text = Color(0xFFE9F1F7);
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
        backgroundColor: Color(0xFF0C141D),
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
