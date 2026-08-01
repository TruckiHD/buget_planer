import 'package:flutter/material.dart';

import 'squircle_input_border.dart';

class AppTheme {
  static ThemeData light() {
    const ink = Color(0xFF172033);
    const canvas = Color(0xFFF5F7FB);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5C6DF2),
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1.4, color: ink),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.5, color: ink),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF667085)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: SquircleInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: Color(0xFFE4E7EC))),
        enabledBorder: SquircleInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: Color(0xFFE4E7EC))),
        focusedBorder: SquircleInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: Color(0xFF5669E8), width: 1.5)),
      ),
    );
  }
}
