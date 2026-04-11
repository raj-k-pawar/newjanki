import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary      = Color(0xFF2D6A4F);
  static const primaryDark  = Color(0xFF1B4332);
  static const primaryLight = Color(0xFF52B788);
  static const accent       = Color(0xFFE9AF37);
  static const background   = Color(0xFFF8F5F0);
  static const cardBg       = Color(0xFFFFFFFF);
  static const textDark     = Color(0xFF1A2E1F);
  static const textMedium   = Color(0xFF4A6741);
  static const textLight    = Color(0xFF8FA88A);
  static const textWhite    = Color(0xFFFFFFFF);
  static const success      = Color(0xFF40916C);
  static const warning      = Color(0xFFF4A261);
  static const error        = Color(0xFFE63946);
  static const cardBlue     = Color(0xFF4361EE);
  static const cardOrange   = Color(0xFFF4A261);
  static const cardPurple   = Color(0xFF7B2D8B);
  static const cardTeal     = Color(0xFF0A9396);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.cardBg,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.textLight.withOpacity(0.4))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.textLight.withOpacity(0.4))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error)),
      hintStyle: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13),
      labelStyle: GoogleFonts.poppins(color: AppColors.textMedium, fontSize: 13),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
  );
}
