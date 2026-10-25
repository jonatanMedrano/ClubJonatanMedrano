import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Toda la estética vive acá. Cambiando estos colores cambia toda la app.
class AppColors {
  // Se mantienen por compatibilidad con las pantallas anteriores.
  static const primary = Color(0xFF1B8A4B);
  static const dark = Color(0xFF0B3D20);
  static const accent = Color(0xFFFFC83D);
  static const bg = Color(0xFFF4F7F5);

  static const verdeDia = Color(0xFF1B8A4B); // verde sobre fondo claro
  static const verdeNoche = Color(0xFF3DDC84); // verde sobre fondo negro
  static const rojo = Color(0xFFE0645F);

  static const ambarDia = Color(0xFFB86E00);
  static const ambarNoche = Color(0xFFFFB347);
  static const indigoDia = Color(0xFF4F5BD5);
  static const indigoNoche = Color(0xFF9AA2FF);
}

/// Atajos de color según el modo (día / noche) activo.
extension ThemeX on BuildContext {
  bool get noche => Theme.of(this).brightness == Brightness.dark;
  Color get verde => Theme.of(this).colorScheme.primary;
  Color get onVerde => Theme.of(this).colorScheme.onPrimary;
  Color get texto => Theme.of(this).colorScheme.onSurface;
  Color get muted => Theme.of(this).colorScheme.onSurface.withAlpha(140);
  Color get superficie => Theme.of(this).colorScheme.surface;
  Color get fondo => Theme.of(this).scaffoldBackgroundColor;
  Color get borde =>
      noche ? Colors.white.withAlpha(30) : const Color(0xFFD9E0DB);
  Color get chipBg =>
      noche ? Colors.white.withAlpha(18) : const Color(0xFFEFF2F0);
}

/// Estilo de títulos: condensado y en negrita.
TextStyle tituloStyle(BuildContext c, {double size = 32, Color? color}) =>
    GoogleFonts.barlowCondensed(
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 1.0,
      letterSpacing: 0.5,
      color: color ?? Theme.of(c).colorScheme.onSurface,
    );

OutlineInputBorder _borde(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w));

/// Aplica la fuente Inter a cada estilo del texto. Se hace a mano porque
/// GoogleFonts.interTextTheme usa otro tipo de TextTheme en las versiones nuevas.
TextTheme _conInter(TextTheme t) {
  TextStyle? f(TextStyle? s) =>
      s == null ? null : GoogleFonts.inter(textStyle: s);
  return t.copyWith(
    displayLarge: f(t.displayLarge),
    displayMedium: f(t.displayMedium),
    displaySmall: f(t.displaySmall),
    headlineLarge: f(t.headlineLarge),
    headlineMedium: f(t.headlineMedium),
    headlineSmall: f(t.headlineSmall),
    titleLarge: f(t.titleLarge),
    titleMedium: f(t.titleMedium),
    titleSmall: f(t.titleSmall),
    bodyLarge: f(t.bodyLarge),
    bodyMedium: f(t.bodyMedium),
    bodySmall: f(t.bodySmall),
    labelLarge: f(t.labelLarge),
    labelMedium: f(t.labelMedium),
    labelSmall: f(t.labelSmall),
  );
}

ThemeData buildTheme(Brightness b) {
  final noche = b == Brightness.dark;
  final verde = noche ? AppColors.verdeNoche : AppColors.verdeDia;
  final fondo = noche ? Colors.black : AppColors.bg;
  final superficie = noche ? const Color(0xFF111413) : Colors.white;
  final texto = noche ? Colors.white : const Color(0xFF0F1A14);
  final borde = noche ? Colors.white24 : const Color(0xFFD5DCD7);

  final scheme =
      ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: b)
          .copyWith(
    primary: verde,
    onPrimary: noche ? Colors.black : Colors.white,
    surface: superficie,
    onSurface: texto,
    error: AppColors.rojo,
  );
  final textTheme = _conInter(ThemeData(brightness: b).textTheme)
      .apply(bodyColor: texto, displayColor: texto);

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: fondo,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: noche ? const Color(0xFF0A0F0C) : AppColors.dark,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.barlowCondensed(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: noche ? Colors.white.withAlpha(20) : Colors.white,
      border: _borde(borde),
      enabledBorder: _borde(borde),
      focusedBorder: _borde(verde, 1.6),
      errorBorder: _borde(AppColors.rojo),
      focusedErrorBorder: _borde(AppColors.rojo, 1.6),
      hintStyle: TextStyle(color: texto.withAlpha(110)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.barlowCondensed(
            fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: superficie,
      indicatorColor: verde.withAlpha(45),
    ),
  );
}

/// Guarda si el usuario eligió modo día, noche o el del sistema.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  ThemeMode mode = ThemeMode.system;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString('theme_mode');
      mode = v == 'dark'
          ? ThemeMode.dark
          : v == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('theme_mode', dark ? 'dark' : 'light');
    } catch (_) {}
  }
}
