import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand Colours (Dark) ─────────────────────────────────────────────────────

const _primarySeed = Color(0xFF00BCD4); // Cyan 400
const _primaryDark = Color(0xFF0097A7); // Cyan 700
const _darkSurface = Color(0xFF1A1E2E);
const _darkBackground = Color(0xFF121520);
const _darkCard = Color(0xFF212638);

// ─── Dark Theme ───────────────────────────────────────────────────────────────

ThemeData darkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _primarySeed,
    brightness: Brightness.dark,
    primary: _primarySeed,
    secondary: _primaryDark,
    surface: _darkSurface,
    surfaceContainerHighest: _darkCard,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _darkBackground,
    textTheme: GoogleFonts.outfitTextTheme().apply(
      bodyColor: const Color(0xFFE8EAF0),
      displayColor: const Color(0xFFE8EAF0),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFE8EAF0),
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFE8EAF0)),
    ),
    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primarySeed,
        foregroundColor: _darkBackground,
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
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primarySeed,
      foregroundColor: _darkBackground,
      elevation: 4,
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF252A3A),
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
        color: const Color(0xFF9CA3AF),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.outfit(color: const Color(0xFF6B7280)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _darkSurface,
      selectedItemColor: _primarySeed,
      unselectedItemColor: const Color(0xFF6B7280),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _darkSurface,
      indicatorColor: _primarySeed.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.outfit(
              fontSize: 11, fontWeight: FontWeight.w600, color: _primarySeed);
        }
        return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280));
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _primarySeed, size: 24);
        }
        return const IconThemeData(color: Color(0xFF6B7280), size: 24);
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF252A3A),
      selectedColor: _primarySeed.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE8EAF0)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2D3348),
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkCard,
      contentTextStyle: GoogleFonts.outfit(
          color: const Color(0xFFE8EAF0), fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
