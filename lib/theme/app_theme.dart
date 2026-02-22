// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette
  static const Color deepRed = Color(0xFF8B0000);
  static const Color crimson = Color(0xFFDC143C);
  static const Color brightRed = Color(0xFFFF1744);
  static const Color bloodRed = Color(0xFF6B0000);

  // Dark palette
  static const Color nearBlack = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF141414);
  static const Color cardSurface = Color(0xFF1C1C1C);
  static const Color elevation = Color(0xFF222222);

  // Green table
  static const Color feltGreen = Color(0xFF1B5E20);
  static const Color feltGreenLight = Color(0xFF2E7D32);
  static const Color feltGreenAccent = Color(0xFF388E3C);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color textMuted = Color(0xFF757575);
  static const Color textGold = Color(0xFFFFD700);

  // Glass
  static const Color glassWhite = Color(0x15FFFFFF);
  static const Color glassBorder = Color(0x30FFFFFF);
  static const Color glassRed = Color(0x20DC143C);

  // Status
  static const Color positive = Color(0xFF4CAF50);
  static const Color negative = Color(0xFFFF5252);
  static const Color neutral = Color(0xFFFFB300);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.nearBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.crimson,
        secondary: AppColors.brightRed,
        surface: AppColors.darkSurface,
        background: AppColors.nearBlack,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.playfairDisplayTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: GoogleFonts.raleway(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        titleMedium: GoogleFonts.raleway(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.raleway(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.raleway(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.raleway(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
          elevation: 8,
          shadowColor: AppColors.crimson.withOpacity(0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.crimson, width: 2),
        ),
        labelStyle: GoogleFonts.raleway(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.raleway(color: AppColors.textMuted),
        prefixIconColor: AppColors.textMuted,
      ),
    );
  }
}