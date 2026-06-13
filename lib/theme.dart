import 'package:flutter/material.dart';

class TacticalTheme {
  static const Color bgPrimary = Color(0xFF0A0E17);
  static const Color bgSecondary = Color(0xFF111827);
  static const Color bgCard = Color(0xFF1E293B);
  
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentGreen = Color(0xFF10B981);
  
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: accentCyan,
      cardColor: bgSecondary,
      hintColor: textMuted,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSecondary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textMain, fontSize: 16),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14),
        titleLarge: TextStyle(color: textMain, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textMain, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentCyan,
        surface: bgSecondary,
        error: accentRed,
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: bgCard,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }
}
