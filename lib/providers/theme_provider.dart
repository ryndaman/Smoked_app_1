// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smoked_1/utils/app_themes.dart';

class ThemeProvider with ChangeNotifier {
  static const _themeKey = 'app_theme';
  ThemeData _themeData;

  ThemeProvider() : _themeData = AppThemes.lightTheme {
    // Set a default light theme
    _loadTheme();
  }

  ThemeData get themeData => _themeData;
  AppTheme get currentTheme {
    if (_themeData == AppThemes.darkTheme) {
      // Check against the new dark theme
      return AppTheme.dark;
    }
    return AppTheme.light; // Default to light
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName =
        prefs.getString(_themeKey) ?? AppTheme.light.name; // Default to 'light'

    if (themeName == AppTheme.dark.name) {
      _themeData = AppThemes.darkTheme;
    } else {
      _themeData = AppThemes.lightTheme;
    }
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();

    if (theme == AppTheme.dark) {
      _themeData = AppThemes.darkTheme;
    } else {
      _themeData = AppThemes.lightTheme;
    }

    await prefs.setString(_themeKey, theme.name);
    notifyListeners();
  }
}
