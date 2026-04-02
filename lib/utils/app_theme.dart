import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary - Deep Forest Green
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color primaryDark = Color(0xFF1B4332);

  // Accent - Warm Amber
  static const Color accent = Color(0xFFE9AF37);
  static const Color accentLight = Color(0xFFF4CC6E);
  static const Color accentDark = Color(0xFFB88B1A);

  // Backgrounds
  static const Color background = Color(0xFFF8F5F0);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color darkBg = Color(0xFF1A2E1F);

  // Text
  static const Color textDark = Color(0xFF1A2E1F);
  static const Color textMedium = Color(0xFF4A6741);
  static const Color textLight = Color(0xFF8FA88A);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF40916C);
  static const Color warning = Color(0xFFF4A261);
  static const Color error = Color(0xFFE63946);
  static const Color info = Color(0xFF4895EF);

  // Dashboard Cards
  static const Color cardBlue = Color(0xFF4361EE);
  static const Color cardGreen = Color(0xFF2D6A4F);
  static const Color cardOrange = Color(0xFFF4A261);
  static const Color cardPurple = Color(0xFF7B2D8B);
  static const Color cardTeal = Color(0xFF0A9396);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        background: AppColors.background,
        surface: AppColors.cardBg,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textMedium,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textWhite,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textLight.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: AppColors.textMedium, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class AppStrings {
  static const String appName = 'Janki Agro Tourism';
  static const String tagline = 'Nature\'s Retreat';

  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String username = 'Username';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String email = 'Email';
  static const String phone = 'Phone Number';
  static const String userType = 'User Type';
  static const String loginBtn = 'Sign In';
  static const String registerBtn = 'Create Account';

  // User Types
  static const String manager = 'Manager';
  static const String owner = 'Owner';
  static const String admin = 'Admin';
  static const String canteen = 'Canteen';

  // Dashboard
  static const String todaysOverview = 'Today\'s Overview';
  static const String totalBookings = 'Total Bookings';
  static const String totalGuests = 'Total Guests';
  static const String totalRevenue = 'Total Revenue';
  static const String cashPayment = 'Cash Payment';
  static const String onlinePayment = 'Online Payment';

  // Buttons
  static const String addNewCustomer = 'Add New Customer';
  static const String viewAllCustomers = 'View All Customers';
  static const String manageWorkers = 'Manage Workers';
}
