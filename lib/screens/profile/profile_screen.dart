import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../provider/category_provider.dart';
import '../../provider/expense_provider.dart';
import '../../provider/theme_provider.dart';
import '../../provider/user_provider.dart';

/// Profile screen showing user details, stats, and navigation to Settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final themeModeStr = ref.watch(themeStringProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar ──────────────────────────────────────────────────
                GestureDetector(
                  onTap: () => context.push(AppRoutes.editProfile),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                        backgroundImage: user.profilePicturePath != null
                            ? FileImage(File(user.profilePicturePath!))
                            : null,
                        child: user.profilePicturePath == null
                            ? Text(
                                user.firstname.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF00BCD4),
                                ),
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BCD4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                const Gap(16),

                // ── Name & DOB ──────────────────────────────────────────────
                Text(
                  user.fullName,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                const Gap(4),

                Text(
                  'Born on ${DateFormatter.toDayMonthYear(DateFormatter.fromIso(user.dob))}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const Gap(24),

                // ── Stats ───────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Spent',
                        value: expensesAsync.maybeWhen(
                          data: (list) {
                            final total = list
                                .where((e) => !e.isIncome)
                                .fold(0.0, (s, e) => s + e.amount);
                            return CurrencyFormatter.compact(total);
                          },
                          orElse: () => '—',
                        ),
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFFFF6B6B),
                        delay: 300,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: _StatCard(
                        title: 'Categories',
                        value: categoriesAsync.maybeWhen(
                          data: (list) => list.length.toString(),
                          orElse: () => '—',
                        ),
                        icon: Icons.category_rounded,
                        color: const Color(0xFFA29BFE),
                        delay: 400,
                      ),
                    ),
                  ],
                ),

                const Gap(24),

                // ── Quick Links ─────────────────────────────────────────────
                Material(
                  color: isDark ? const Color(0xFF252A3A) : Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: isDark
                        ? BorderSide.none
                        : BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      _ProfileListTile(
                        icon: Icons.palette_outlined,
                        iconColor: const Color(0xFF00BCD4),
                        title: 'Theme',
                        trailing: themeModeStr.toUpperCase(),
                        onTap: () => context.push(AppRoutes.settings),
                      ),
                      const Divider(height: 1),
                      _ProfileListTile(
                        icon: Icons.category_outlined,
                        iconColor: const Color(0xFFA29BFE),
                        title: 'Manage Categories',
                        onTap: () => context.push(AppRoutes.categories),
                      ),
                      const Divider(height: 1),
                      _ProfileListTile(
                        icon: Icons.backup_outlined,
                        iconColor: const Color(0xFF10B981),
                        title: 'Backup & Restore',
                        onTap: () => context.push(AppRoutes.backup),
                      ),
                      const Divider(height: 1),
                      _ProfileListTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFFFBBF24),
                        title: 'About Spencer',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: AppConstants.appName,
                            applicationVersion: AppConstants.appVersion,
                            applicationLegalese: '© 2026 The Tech Forge',
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _ProfileListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          const Gap(8),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.3)),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252A3A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? null
            : Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const Gap(12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Gap(2),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
