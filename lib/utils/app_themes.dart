// lib/utils/app_themes.dart

import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData original = ThemeData(
    primaryColor: const Color(0xFF8D6E63),
    scaffoldBackgroundColor: const Color(0xFFFFFFF0),
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF8D6E63), // Brown
      secondary: Color(0xFF5D4037), // Dark Brown
      surface: Color(0xFFFFFFF0), // Ivory
      onPrimary: Colors.white,
      onSurface: Color(0xFF3E2723), // Darkest Brown
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFF0),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF5D4037)),
      titleTextStyle: TextStyle(
        color: Color(0xFF5D4037),
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    ),
  );

  static final ThemeData lightMonochrome = ThemeData(
    primaryColor: const Color(0xFF424242),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF424242), // Dark Grey
      secondary: Color(0xFF212121), // Almost Black
      surface: Color(0xFFFAFAFA), // Off-white
      onPrimary: Colors.white,
      onSurface: Colors.black,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFAFAFA),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF212121)),
      titleTextStyle: TextStyle(
        color: Color(0xFF212121),
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    ),
  );

  static final ThemeData darkNeon = ThemeData(
    primaryColor: const Color(0xFF00E5FF),
    scaffoldBackgroundColor: const Color(0xFF121212),
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00E5FF), // Cyan
      secondary: Color(0xFF00B8D4), // Darker Cyan
      surface: Color(0xFF1E1E1E), // Dark Grey
      onPrimary: Colors.black,
      onSurface: Colors.white,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF00E5FF)),
      titleTextStyle: TextStyle(
        color: Color(0xFF00E5FF),
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    ),
  );
}

enum AppTheme { original, lightMonochrome, darkNeon }
