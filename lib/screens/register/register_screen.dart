import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/pref_keys.dart';
import '../../core/routes/app_router.dart';
import '../../provider/user_provider.dart';
import '../../provider/theme_provider.dart';

/// Registration screen for first-time users.
/// Collects name, DOB, and theme preference before entering the app.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  DateTime? _dob;
  String _theme = 'system';
  bool _isSaving = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      // Insert into database
      final id = await ref.read(userRepositoryProvider).insertUser(
            firstname: _firstNameCtrl.text.trim(),
            middlename: _middleNameCtrl.text.trim().isEmpty
                ? null
                : _middleNameCtrl.text.trim(),
            lastname: _lastNameCtrl.text.trim(),
            theme: _theme,
            dob: DateFormat('yyyy-MM-dd').format(_dob!),
          );

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.isRegistered, true);
      await prefs.setInt(PrefKeys.userId, id);
      await prefs.setString(PrefKeys.theme, _theme);

      // Apply theme
      final mode = switch (_theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      await ref.read(themeProvider.notifier).setTheme(mode);

      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset('assets/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF00BCD4),
                                        Color(0xFF0097A7)
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                      child: Text('S',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 24))),
                                )),
                      ),
                    ),
                    const Gap(12),
                    Text(
                      AppConstants.appName,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideY(
                      begin: -0.2,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const Gap(36),

                Text(
                  'Welcome! 👋',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideX(
                      begin: -0.15,
                      end: 0,
                      delay: 100.ms,
                      duration: 500.ms,
                    ),

                Text(
                  "Let's set up your account before you start tracking.",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const Gap(36),

                // ── Name fields ────────────────────────────────────────────
                _sectionLabel('Your Name'),
                const Gap(12),

                TextFormField(
                  controller: _firstNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'First Name *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'First name is required'
                      : null,
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(
                      begin: -0.1,
                      end: 0,
                      delay: 300.ms,
                      duration: 400.ms,
                    ),

                const Gap(14),

                TextFormField(
                  controller: _middleNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Middle Name (optional)',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ).animate().fadeIn(delay: 360.ms, duration: 400.ms).slideX(
                      begin: -0.1,
                      end: 0,
                      delay: 360.ms,
                      duration: 400.ms,
                    ),

                const Gap(14),

                TextFormField(
                  controller: _lastNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Last Name *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Last name is required' : null,
                ).animate().fadeIn(delay: 420.ms, duration: 400.ms).slideX(
                      begin: -0.1,
                      end: 0,
                      delay: 420.ms,
                      duration: 400.ms,
                    ),

                const Gap(28),

                // ── Date of birth ──────────────────────────────────────────
                _sectionLabel('Date of Birth'),
                const Gap(12),

                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF252A3A)
                          : const Color(0xFFEFF7F9),
                      borderRadius: BorderRadius.circular(14),
                      border: _dob == null
                          ? null
                          : Border.all(
                              color: const Color(0xFF00BCD4), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: _dob != null
                              ? const Color(0xFF00BCD4)
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const Gap(12),
                        Text(
                          _dob != null
                              ? DateFormat('d MMMM yyyy').format(_dob!)
                              : 'Select date of birth',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: _dob != null
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: _dob != null
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 480.ms, duration: 400.ms).slideX(
                      begin: -0.1,
                      end: 0,
                      delay: 480.ms,
                      duration: 400.ms,
                    ),

                const Gap(28),

                // ── Theme selection ────────────────────────────────────────
                _sectionLabel('Preferred Theme'),
                const Gap(12),

                Row(
                  children: [
                    _themeOption('system', '⚙️', 'System'),
                    const Gap(10),
                    _themeOption('light', '☀️', 'Light'),
                    const Gap(10),
                    _themeOption('dark', '🌙', 'Dark'),
                  ],
                ).animate().fadeIn(delay: 540.ms, duration: 400.ms),

                const Gap(48),

                // ── Save button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Get Started',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 640.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      delay: 640.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF00BCD4),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _themeOption(String value, String emoji, String label) {
    final isSelected = _theme == value;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _theme = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00BCD4).withValues(alpha: 0.15)
                : (isDark
                    ? const Color(0xFF252A3A)
                    : const Color(0xFFEFF7F9)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00BCD4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const Gap(6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF00BCD4)
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
