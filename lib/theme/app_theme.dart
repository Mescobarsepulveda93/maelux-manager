import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00B4D8);
  static const Color secondaryColor = Color(0xFF0077B6);
  static const Color accentColor = Color(0xFFFFB703);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),

    scaffoldBackgroundColor: Colors.white,

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
  );
}
