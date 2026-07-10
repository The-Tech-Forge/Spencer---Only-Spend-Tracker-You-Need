/// Keys used with SharedPreferences throughout the application.
/// Centralised here to prevent typos and duplication.
class PrefKeys {
  PrefKeys._();

  /// Whether the user has completed registration.
  static const String isRegistered = 'is_registered';

  /// The stored user ID (int) in the local database.
  static const String userId = 'user_id';

  /// The selected theme: 'system' | 'light' | 'dark'
  static const String theme = 'theme';

  /// True on very first launch; used to seed default categories.
  static const String isFirstLaunch = 'is_first_launch';
}
