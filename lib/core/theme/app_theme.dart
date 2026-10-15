import 'package:flutter/material.dart';

/// Palette centrale de l'application — thème clair.
class AppColors {
  AppColors._();

  static const Color violet = Color(0xFF6C5CE7);
  static const Color teal = Color(0xFF14B8A6);
  static const Color orange = Color(0xFFF59E0B);
  static const Color vert = Color(0xFF22C55E);
  static const Color rouge = Color(0xFFEF4444);
  static const Color gris = Color(0xFF9CA3AF);

  // Light, airy background + white cards with a soft shadow instead of
  // a dark glass look.
  static const Color background = Color(0xFFF6F6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceGlass = Color(0xFFFFFFFF); // kept for API compat with existing widgets
  static const Color borderGlass = Color(0xFFEDEDF2);

  static const Color textPrimary = Color(0xFF1C1C24);
  static const Color textSecondary = Color(0xFF6B6B76);
  static const Color textMuted = Color(0xFF9C9CA6);

  /// Couleur associée à un statut de bloc / log.
  static Color statusColor(String status) {
    switch (status) {
      case 'done':
        return vert;
      case 'partial':
        return orange;
      case 'skipped':
        return rouge;
      case 'pending':
      default:
        return gris;
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.light,
        primary: AppColors.violet,
        secondary: AppColors.teal,
        surface: AppColors.surface,
        error: AppColors.rouge,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.violet,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.violet,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderGlass),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderGlass),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.rouge),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.violet),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.background,
        side: const BorderSide(color: AppColors.borderGlass),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.violet,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderGlass, thickness: 1),
    );
  }
}
