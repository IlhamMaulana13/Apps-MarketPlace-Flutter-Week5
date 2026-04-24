import 'package:appsmarketplace/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // ── LIGHT ────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light, // ← terang
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        primary: AppColors.primary, // ← biru tua
        surface: AppColors.surface, // ← putih
      ),
      scaffoldBackgroundColor: AppColors.background, // ← abu muda
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary, // ← biru tua
        foregroundColor: Colors.white,
      ),
      // ...
    );
  }

  // ── DARK ─────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark, // ← gelap
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        primary: AppColors.accent, // ← biru MUDA (lebih kontras digelap)
        surface: AppColors.darkSurface, // ← abu gelap
      ),
      scaffoldBackgroundColor: AppColors.darkBackground, // ← hitam gelap
      appBarTheme: AppBarTheme(
        backgroundColor:
            AppColors.darkSurface, // ← abu gelap (bukan hitam polos)
        foregroundColor: AppColors.darkTextPrimary, // ← putih keabu
      ),
      // ...
    );
  }
}
