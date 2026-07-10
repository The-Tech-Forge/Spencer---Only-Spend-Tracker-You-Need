import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand Colours ───────────────────────────────────────────────────────────

const _primarySeed = Color(0xFF00BCD4); // Cyan 400
const _primaryDark = Color(0xFF0097A7); // Cyan 700
const _surface = Color(0xFFF8FAFB);
const _background = Color(0xFFF2F5F8);

// ─── Light Theme ─────────────────────────────────────────────────────────────

ThemeData lightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _primarySeed,
    brightness: Brightness.light,
    primary: _primarySeed,
    secondary: _primaryDark,
    surface: _surface,
    surfaceContainerHighest: const Color(0xFFE8F4F6),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _background,
    textTheme: GoogleFonts.outfitTextTheme().apply(
      bodyColor: const Color(0xFF1A1E2E),
      displayColor: const Color(0xFF1A1E2E),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1E2E),
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1A1E2E)),
    ),
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 0,
      shadowColor: _primarySeed.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primarySeed,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primarySeed,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEFF7F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primarySeed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      labelStyle: GoogleFonts.outfit(
        color: const Color(0xFF6B7280),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surface,
      selectedItemColor: _primarySeed,
      unselectedItemColor: Color(0xFF9CA3AF),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _surface,
      indicatorColor: _primarySeed.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.outfit(
              fontSize: 11, fontWeight: FontWeight.w600, color: _primarySeed);
        }
        return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF9CA3AF));
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _primarySeed, size: 24);
        }
        return const IconThemeData(color: Color(0xFF9CA3AF), size: 24);
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFE8F4F6),
      selectedColor: _primarySeed.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      labelStyle:
          GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E7EB),
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1A1E2E),
      contentTextStyle:
          GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
