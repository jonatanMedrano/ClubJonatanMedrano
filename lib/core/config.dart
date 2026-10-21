class Config {
  /// Emulador Android -> tu PC es 10.0.2.2. En producción se pasa la URL de Render:
  /// flutter run --dart-define=API_URL=https://tu-api.onrender.com
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
}
