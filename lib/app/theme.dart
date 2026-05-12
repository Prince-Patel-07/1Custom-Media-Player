import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFBF6A02),
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: baseScheme.copyWith(
      primary: const Color(0xFFF29F05),
      secondary: const Color(0xFF57C7B6),
      surface: const Color(0xFF171B24),
      surfaceContainerHighest: const Color(0xFF202736),
    ),
    scaffoldBackgroundColor: const Color(0xFF0E1117),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF171B24).withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 15, height: 1.35),
    ),
  );
}
