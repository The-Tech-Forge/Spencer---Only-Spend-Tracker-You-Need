import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../provider/theme_provider.dart';
import '../../provider/user_provider.dart';

/// Settings screen for configuring app preferences (Theme, etc).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Appearance',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF00BCD4),
              letterSpacing: 0.8,
            ),
          ).animate().fadeIn(duration: 400.ms),

          const Gap(16),

          // ── Theme Selector ────────────────────────────────────────────
          Material(
            color: isDark ? const Color(0xFF252A3A) : Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: isDark
                  ? BorderSide.none
                  : BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
            ),
            child: Column(
              children: [
                _ThemeRadioListTile(
                  title: 'System Default',
                  icon: Icons.settings_brightness_rounded,
                  value: ThemeMode.system,
                  groupValue: currentTheme,
                  onChanged: (val) => _updateTheme(context, ref, val),
                ),
                const Divider(),
                _ThemeRadioListTile(
                  title: 'Light',
                  icon: Icons.light_mode_rounded,
                  value: ThemeMode.light,
                  groupValue: currentTheme,
                  onChanged: (val) => _updateTheme(context, ref, val),
                ),
                const Divider(),
                _ThemeRadioListTile(
                  title: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  value: ThemeMode.dark,
                  groupValue: currentTheme,
                  onChanged: (val) => _updateTheme(context, ref, val),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
                begin: 0.1,
                end: 0,
              ),

          const Gap(40),

          // Future settings placeholders could go here...
        ],
      ),
    );
  }

  Future<void> _updateTheme(
      BuildContext context, WidgetRef ref, ThemeMode? mode) async {
    if (mode == null) return;
    
    // Update provider (persists to SharedPreferences automatically)
    await ref.read(themeProvider.notifier).setTheme(mode);

    // Update user record in database if available
    final user = ref.read(userProvider).value;
    if (user != null) {
      final themeStr = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
      await ref.read(userRepositoryProvider).updateUser(
            user.copyWith(theme: themeStr),
          );
      // Invalidate user provider to reload data
      ref.invalidate(userProvider);
    }
  }
}

class _ThemeRadioListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode?> onChanged;

  const _ThemeRadioListTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Text(title, style: GoogleFonts.outfit()),
      secondary: Icon(icon,
          color: groupValue == value
              ? const Color(0xFF00BCD4)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
      activeColor: const Color(0xFF00BCD4),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
