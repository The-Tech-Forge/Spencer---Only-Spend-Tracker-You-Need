import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/pref_keys.dart';

/// Notifier that manages [ThemeMode] and persists the selection via SharedPreferences.
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Default to system theme; actual value loaded via [loadSavedTheme].
    return ThemeMode.system;
  }

  /// Reads the stored theme from SharedPreferences and updates state.
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(PrefKeys.theme) ?? 'system';
    state = _fromString(saved);
  }

  /// Changes the theme and immediately persists to SharedPreferences.
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.theme, _toString(mode));
  }

  ThemeMode _fromString(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  String _toString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
}

/// The primary theme provider used in MaterialApp.
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

/// Convenience provider returning the string representation of the current theme.
final themeStringProvider = Provider<String>((ref) {
  final mode = ref.watch(themeProvider);
  return switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    _ => 'system',
  };
});
