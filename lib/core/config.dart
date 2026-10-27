class Config {
  // desde el emulador mi pc se ve como 10.0.2.2. para apuntar a render se pasa la url al compilar: flutter run
  // --dart-define=API_URL=https://club-jonatan-api.onrender.com
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
}
