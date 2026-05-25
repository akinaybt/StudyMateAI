import 'package:flutter/material.dart';

class AppTheme {
  // From your theme.css
  static const primary = Color(0xFF030213);
  static const destructive = Color(0xFFD4183D);
  static const inputBackground = Color(0xFFF3F3F5);
  static const card = Color(0xFFFFFFFF);

  static const radius = 10.0; // 0.625rem * 16 = 10px
  static const borderOpacity = 0.10;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1), // indigo-ish seed
      brightness: Brightness.light,
      primary: primary,
      error: destructive,
      surface: card,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: Colors.black.withOpacity(borderOpacity)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: Colors.black.withOpacity(borderOpacity)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Color(0xFF818CF8)), // indigo-400-ish
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}