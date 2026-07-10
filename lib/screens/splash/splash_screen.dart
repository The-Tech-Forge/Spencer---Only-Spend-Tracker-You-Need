import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/pref_keys.dart';
import '../../core/routes/app_router.dart';
import '../../provider/category_provider.dart';
import '../../provider/theme_provider.dart';

/// Splash screen displayed on app launch.
/// Shows animated logo, then navigates to Register or Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Load saved theme preference
    await ref.read(themeProvider.notifier).loadSavedTheme();

    // Seed default categories on first launch
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(PrefKeys.isFirstLaunch) ?? true;
    if (isFirstLaunch) {
      await ref.read(categoryRepositoryProvider).seedDefaultCategories();
      await prefs.setBool(PrefKeys.isFirstLaunch, false);
    }

    // Wait for the splash animation to play
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;

    // Decide navigation target
    final isRegistered = prefs.getBool(PrefKeys.isRegistered) ?? false;
    if (isRegistered) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121520) : const Color(0xFFF2F5F8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo ──────────────────────────────────────────────────────
            _buildLogo()
                .animate()
                .blur(
                  begin: const Offset(20, 20),
                  end: Offset.zero,
                  duration: 900.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(duration: 700.ms)
                .scaleXY(
                  begin: 0.6,
                  end: 1.0,
                  duration: 900.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 32),

            // ── App name ──────────────────────────────────────────────────
            Text(
              AppConstants.appName,
              style: GoogleFonts.outfit(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? const Color(0xFFE8EAF0)
                    : const Color(0xFF1A1E2E),
                letterSpacing: -1.5,
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 600.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 600.ms,
                  duration: 600.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 8),

            // ── Tagline ───────────────────────────────────────────────────
            Text(
              AppConstants.appTagline,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF00BCD4),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 900.ms, duration: 500.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 900.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 80),

            // ── Loading indicator ─────────────────────────────────────────
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: isDark
                    ? const Color(0xFF252A3A)
                    : const Color(0xFFE0F7FA),
                color: const Color(0xFF00BCD4),
                borderRadius: BorderRadius.circular(4),
                minHeight: 3,
              ),
            )
                .animate()
                .fadeIn(delay: 1200.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Center(
              child: Text('S',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
