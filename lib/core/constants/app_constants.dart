class AppConstants {
  static const String appName = 'SpendWise Finance';
  static const String appTagline = 'Master Your Personal Wealth';

  // Default API configuration
  // For local development on Android Emulator: http://10.0.2.2/Personal%20Finance%20Tracker
  // For local web/desktop preview: http://localhost/Personal%20Finance%20Tracker
  static const String defaultLocalApiUrl = 'http://localhost/Personal%20Finance%20Tracker';

  // SharedPreferences Keys
  static const String keyApiBaseUrl = 'pref_api_base_url';
  static const String keyIsDemoMode = 'pref_is_demo_mode';
  static const String keyThemeMode = 'pref_theme_mode';
  static const String keyUserSession = 'pref_user_session';
  static const String keyCurrencySymbol = 'pref_currency_symbol';

  // Default Currency
  static const String defaultCurrency = '\$';
}
