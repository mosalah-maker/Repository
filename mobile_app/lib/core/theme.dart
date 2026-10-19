import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData darkTheme() {
    final textTheme = GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppConstants.darkBg,
      primaryColor: AppConstants.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primary,
        secondary: AppConstants.secondary,
        surface: AppConstants.darkCard,
        error: AppConstants.danger,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: AppConstants.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.darkBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppConstants.darkCard,
        selectedItemColor: AppConstants.primary,
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
