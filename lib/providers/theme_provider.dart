// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smoked_1/utils/app_themes.dart';

class ThemeProvider with ChangeNotifier {
  static const _themeKey = 'app_theme';
  ThemeData _themeData;

  ThemeProvider() : _themeData = AppThemes.original {
    _loadTheme();
  }

  ThemeData get themeData => _themeData;
  AppTheme get currentTheme {
    if (_themeData == AppThemes.lightMonochrome) {
      return AppTheme.lightMonochrome;
    }
    if (_themeData == AppThemes.darkNeon) {
      return AppTheme.darkNeon;
    }
    return AppTheme.original;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? AppTheme.original.name;

    if (themeName == AppTheme.lightMonochrome.name) {
      _themeData = AppThemes.lightMonochrome;
    } else if (themeName == AppTheme.darkNeon.name) {
      _themeData = AppThemes.darkNeon;
    } else {
      _themeData = AppThemes.original;
    }
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();

    if (theme == AppTheme.lightMonochrome) {
      _themeData = AppThemes.lightMonochrome;
    } else if (theme == AppTheme.darkNeon) {
      _themeData = AppThemes.darkNeon;
    } else {
      _themeData = AppThemes.original;
    }

    await prefs.setString(_themeKey, theme.name);
    notifyListeners();
  }
}
