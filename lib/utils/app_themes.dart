import 'package:flutter/material.dart';

class AppThemes {
  // NEW: Define the Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF424242), // Dark Grey, can be adjusted
    scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Off-white background
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF424242), // Dark Grey for primary elements
      secondary: Color(0xFF212121), // Almost Black for accents
      surface: Color(0xFFFAFAFA), // Off-white surface
      onPrimary: Colors.white,
      onSurface: Colors.black, // Black text on light surfaces
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

  // Renamed from darkNeon to darkTheme
  static final ThemeData darkTheme = ThemeData(
    primaryColor: const Color(0xFF00E5FF), // Cyan, can be adjusted
    scaffoldBackgroundColor: const Color(0xFF121212), // Dark background
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00E5FF), // Cyan for primary elements
      secondary: Color(0xFF00B8D4), // Darker Cyan for accents
      surface: Color(0xFF1E1E1E), // Dark Grey surface
      onPrimary: Colors.black,
      onSurface: Colors.white, // White text on dark surfaces
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

enum AppTheme { light, dark } // Updated enum
