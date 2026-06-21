import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF0A1628);
  static const Color accent = Color(0xFF2563EB);
  static const Color accentLight = Color(0xFF3B82F6);
  static const Color gold = Color(0xFFD4A843);
  static const Color surface = Color(0xFF111827);
  static const Color card = Color(0xFF1C2E4A);
  static const Color cardLight = Color(0xFF243450);
  static const Color textPrimary = Color(0xFFE8EDF5);
  static const Color textSecondary = Color(0xFF8A9BB5);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: primary,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: gold,
          surface: surface,
          error: danger,
        ),
        textTheme: GoogleFonts.outfitTextTheme().apply(
          bodyColor: textPrimary,
          displayColor: textPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
}
