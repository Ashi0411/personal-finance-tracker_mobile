import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default to clean, modern Light Mode like web app
  String _currencySymbol = '\$';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get currencySymbol => _currencySymbol;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(AppConstants.keyThemeMode);
    if (savedMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    _currencySymbol = prefs.getString(AppConstants.keyCurrencySymbol) ?? '\$';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setCurrency(String symbol) async {
    _currencySymbol = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyCurrencySymbol, symbol);
    notifyListeners();
  }
}
