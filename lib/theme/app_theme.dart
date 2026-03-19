import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const ink = Color(0xff050816);
  static const panel = Color(0xff111827);
  static const panelSoft = Color(0xff172033);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xffcbd5e1);
  static const textMuted = Color(0xff94a3b8);
  static const accent = Color(0xff38bdf8);
}

class AppTextStyles {
  AppTextStyles._();

  static const display = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -0.8,
  );

  static const hero = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.08,
    letterSpacing: -0.7,
  );

  static const sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static const cardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.3,
  );

  static const body = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    height: 1.55,
    letterSpacing: 0.1,
  );

  static const caption = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const statValue = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = const ColorScheme.dark(
      primary: Color(0xff38bdf8),
      secondary: Color(0xff22d3ee),
      surface: AppColors.panel,
      onSurface: AppColors.textPrimary,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ink,
      textTheme: base.textTheme.copyWith(
        displaySmall: AppTextStyles.display,
        headlineMedium: AppTextStyles.hero,
        titleLarge: AppTextStyles.sectionTitle,
        titleMedium: AppTextStyles.cardTitle,
        bodyMedium: AppTextStyles.body,
        labelMedium: AppTextStyles.caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: AppColors.ink,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.panel,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
