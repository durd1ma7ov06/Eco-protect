import 'package:flutter/material.dart';

class AppTheme {
  // EcoProject Luxury Light / Milk Palette
  static const Color primaryEmerald = Color(0xFF059669);
  static const Color primaryDark = Color(0xFF064E3B);
  static const Color creamBg = Color(0xFFF8FAF7);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentAmber = Color(0xFFD97706);
  static const Color accentRose = Color(0xFFE11D48);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: creamBg,
    colorScheme: const ColorScheme.light(
      primary: primaryEmerald,
      secondary: accentTeal,
      surface: surfaceWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: creamBg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: textDark,
        fontFamily: 'sans-serif',
      ),
      iconTheme: IconThemeData(color: textDark),
    ),
    cardTheme: CardThemeData(
      color: surfaceWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: borderLight, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
