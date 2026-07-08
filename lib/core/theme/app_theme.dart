import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium dark "institutional terminal" theme used across the whole app.
/// Centralizing colors here means every screen automatically stays
/// visually consistent, and re-theming later (e.g. light mode) is a
/// one-file change.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF141821);
  static const Color surfaceElevated = Color(0xFF1B2130);
  static const Color border = Color(0xFF262E3D);

  static const Color primary = Color(0xFF3D8BFF); // institutional blue
  static const Color accentGold = Color(0xFFD4AF37); // premium gold accent

  static const Color profit = Color(0xFF17C964);
  static const Color loss = Color(0xFFF31260);
  static const Color warning = Color(0xFFF5A524);

  static const Color textPrimary = Color(0xFFEDEFF3);
  static const Color textSecondary = Color(0xFF8B93A7);
  static const Color textMuted = Color(0xFF5A6178);

  // Emotion tag colors
  static const Color emotionCalm = Color(0xFF17C964);
  static const Color emotionConfident = Color(0xFF3D8BFF);
  static const Color emotionNegative = Color(0xFFF31260);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accentGold,
        surface: AppColors.surface,
        error: AppColors.loss,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dividerColor: AppColors.border,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceElevated,
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
