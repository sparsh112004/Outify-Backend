import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant gradients and sleek surfaces
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color secondaryColor = Color(0xFF7C3AED); // Violet 600
  static const Color accentColor = Color(0xFF06B6D4);  // Cyan 500
  
  static const double borderRadius = 20.0;

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: const Color(0xFF7C3AED), // Violet 600
        tertiary: accentColor,
        surface: const Color(0xFFF1F5F9), // Slate 100
        error: const Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        color: Colors.white,
      ),
      inputDecorationTheme: _inputDecorationTheme(Brightness.light),
      filledButtonTheme: _filledButtonTheme(primaryColor),
      outlinedButtonTheme: _outlinedButtonTheme(primaryColor),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryLight,
        secondary: const Color(0xFFA78BFA),
        tertiary: const Color(0xFF22D3EE),
        surface: const Color(0xFF0F172A), // Slate 900
        surfaceContainerHighest: const Color(0xFF1E293B), // Slate 800
      ),
      scaffoldBackgroundColor: const Color(0xFF020617), // Slate 950
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        color: const Color(0xFF0F172A),
      ),
      inputDecorationTheme: _inputDecorationTheme(Brightness.dark),
      filledButtonTheme: _filledButtonTheme(primaryLight),
      outlinedButtonTheme: _outlinedButtonTheme(primaryLight),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5), width: 2),
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(Color color) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: color,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(Color color) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide(color: color, width: 2),
        foregroundColor: color,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  // Helper for consistent box shadows
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
}

