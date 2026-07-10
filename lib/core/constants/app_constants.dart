/// Application-wide string constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Spencer';
  static const String appTagline = 'Only Spend Tracker You Need';
  static const String appVersion = '1.0.0';

  /// Default categories seeded on first launch.
  static const List<Map<String, String>> defaultCategories = [
    {'category': 'Food', 'emoji': '🍔'},
    {'category': 'Shopping', 'emoji': '🛒'},
    {'category': 'Travel', 'emoji': '✈️'},
    {'category': 'Fuel', 'emoji': '⛽'},
    {'category': 'Medical', 'emoji': '🏥'},
    {'category': 'Entertainment', 'emoji': '🎮'},
    {'category': 'Bills', 'emoji': '💡'},
    {'category': 'Education', 'emoji': '📚'},
    {'category': 'Investment', 'emoji': '📈'},
    {'category': 'Salary', 'emoji': '💰'},
    {'category': 'Others', 'emoji': '📦'},
  ];
}
