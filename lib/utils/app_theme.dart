import 'package:flutter/material.dart';

import 'squircle_input_border.dart';

class AppColors {
  // Shared accent colors
  static const primary = Color(0xFF5669E8);
  static const green = Color(0xFF20966A);
  static const red = Color(0xFFD94E5A);
  static const amber = Color(0xFFE19A35);
  static const pink = Color(0xFFE05B9A);

  // Light theme colors
  static const lightBg = Color(0xFFF5F7FB);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF172033);
  static const lightSecondary = Color(0xFF667085);
  static const lightMuted = Color(0xFF78839A);
  static const lightBorder = Color(0xFFE4E7EC);
  static const lightChipBg = Color(0xFFEFF1FF);
  static const lightDivider = Color(0xFFE9ECF4);
  static const lightCardShadow = Color(0x0D172033);

  // Dark theme colors
  static const darkBg = Color(0xFF0F1118);
  static const darkSurface = Color(0xFF1A1D2E);
  static const darkSurface2 = Color(0xFF232740);
  static const darkText = Color(0xFFEAEDF6);
  static const darkSecondary = Color(0xFF98A2B3);
  static const darkMuted = Color(0xFF6B7280);
  static const darkBorder = Color(0xFF2D3148);
  static const darkChipBg = Color(0xFF252842);
  static const darkDivider = Color(0xFF2D3148);
  static const darkCardShadow = Color(0x20000000);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.lightSurface,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1.4, color: AppColors.lightText),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.5, color: AppColors.lightText),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.lightText),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.lightSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: SquircleInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.lightBorder)),
        enabledBorder: SquircleInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.lightBorder)),
        focusedBorder: SquircleInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1.4, color: AppColors.darkText),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.5, color: AppColors.darkText),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface2,
        border: SquircleInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.darkBorder)),
        enabledBorder: SquircleInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.darkBorder)),
        focusedBorder: SquircleInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}
