import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes/app_router.dart';

/// Persistent bottom navigation shell wrapping the four main tabs.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = [
    AppRoutes.home,
    AppRoutes.expense,
    AppRoutes.analytics,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    int currentIndex = _tabs.indexWhere(
      (t) => currentLocation.startsWith(t),
    );
    if (currentIndex < 0) currentIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: _SpencerNavBar(
        currentIndex: currentIndex,
        onTap: (index) => context.go(_tabs[index]),
      ),
    );
  }
}

class _SpencerNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SpencerNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      animationDuration: const Duration(milliseconds: 300),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        _dest(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Home',
          labelStyle: GoogleFonts.outfit(),
        ),
        _dest(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          label: 'Expenses',
          labelStyle: GoogleFonts.outfit(),
        ),
        _dest(
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart_rounded,
          label: 'Analytics',
          labelStyle: GoogleFonts.outfit(),
        ),
        _dest(
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          label: 'Profile',
          labelStyle: GoogleFonts.outfit(),
        ),
      ],
    );
  }

  NavigationDestination _dest({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    TextStyle? labelStyle,
  }) {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
    );
  }
}
