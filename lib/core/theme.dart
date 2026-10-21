import 'package:flutter/material.dart';

/// Toda la estética vive acá. Cambiando estos colores cambia toda la app.
class AppColors {
  static const primary = Color(0xFF1B8A4B);
  static const dark = Color(0xFF0B3D20);
  static const accent = Color(0xFFFFC83D);
  static const bg = Color(0xFFF4F7F5);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary, primary: AppColors.primary),
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.dark, foregroundColor: Colors.white),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
