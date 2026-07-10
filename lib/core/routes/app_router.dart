import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/splash/splash_screen.dart';
import '../../screens/register/register_screen.dart';
import '../../screens/shell/app_shell.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/expense/expense_screen.dart';
import '../../screens/expense/add_expense_screen.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/backup_restore_screen.dart';
import '../../screens/category/category_manage_screen.dart';

/// Named route paths — centralised to avoid magic strings.
abstract class AppRoutes {
  static const splash = '/';
  static const register = '/register';
  static const home = '/home';
  static const expense = '/expense';
  static const addExpense = '/expense/add';
  static const editExpense = '/expense/edit';
  static const analytics = '/analytics';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const settings = '/settings';
  static const backup = '/settings/backup';
  static const categories = '/categories';
}

/// Application-wide GoRouter configuration.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    // ── Splash ──────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => _buildPage(state, const SplashScreen()),
    ),

    // ── Register ────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.register,
      pageBuilder: (context, state) =>
          _buildPage(state, const RegisterScreen()),
    ),

    // ── Settings (standalone) ───────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) =>
          _buildPage(state, const SettingsScreen()),
    ),

    // ── Backup & Restore ────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.backup,
      pageBuilder: (context, state) =>
          _buildPage(state, const BackupRestoreScreen()),
    ),

    // ── Edit Profile ────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.editProfile,
      pageBuilder: (context, state) =>
          _buildPage(state, const EditProfileScreen()),
    ),

    // ── Category Management ──────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.categories,
      pageBuilder: (context, state) =>
          _buildPage(state, const CategoryManageScreen()),
    ),

    // ── Add/Edit Expense ────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.addExpense,
      pageBuilder: (context, state) =>
          _buildPage(state, const AddExpenseScreen()),
    ),
    GoRoute(
      path: '${AppRoutes.editExpense}/:id',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return _buildPage(state, AddExpenseScreen(editId: id));
      },
    ),

    // ── Shell with bottom navigation ─────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) =>
              _noTransitionPage(const HomeScreen()),
        ),
        GoRoute(
          path: AppRoutes.expense,
          pageBuilder: (context, state) =>
              _noTransitionPage(const ExpenseScreen()),
        ),
        GoRoute(
          path: AppRoutes.analytics,
          pageBuilder: (context, state) =>
              _noTransitionPage(const AnalyticsScreen()),
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (context, state) =>
              _noTransitionPage(const ProfileScreen()),
        ),
      ],
    ),
  ],
);

/// Builds a page with a fade transition for overlay screens.
CustomTransitionPage<void> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// No-transition page for bottom nav tabs (avoids double animation).
NoTransitionPage<void> _noTransitionPage(Widget child) {
  return NoTransitionPage<void>(child: child);
}
