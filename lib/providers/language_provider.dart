import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String keyLanguage = 'app_language_code';
  
  String _currentLanguage = 'en'; // 'en' or 'si'

  String get currentLanguage => _currentLanguage;
  bool get isSinhala => _currentLanguage == 'si';
  bool get isEnglish => _currentLanguage == 'en';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(keyLanguage) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (langCode == _currentLanguage) return;
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLanguage, langCode);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    final newLang = _currentLanguage == 'en' ? 'si' : 'en';
    await setLanguage(newLang);
  }
}
