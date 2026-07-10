import 'package:shared_preferences/shared_preferences.dart';

class SavePref<T> {
  /// Save Data
  static Future<void> savePrefs<T>({
    required String key,
    required T value,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else {
      throw Exception("Unsupported Type");
    }
  }

  /// Read Data
  static Future<T?> getPrefs<T>({required String key}) async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.get(key);

    return data as T?;
  }

  /// Remove Single Key
  static Future<void> removePrefs({required String key}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(key);
  }

  /// Clear All Data
  static Future<void> clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}
