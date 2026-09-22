class ApiConfig {
  static const String _envApiUrl = String.fromEnvironment('API_URL', defaultValue: '');

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static String get baseUrl {
    if (_envApiUrl.isNotEmpty) return _envApiUrl;

    // URL unificada: en el PC apunta al Flask local, y en el teléfono físico
    // llega al PC a través de `adb reverse tcp:5000 tcp:5000`.
    // Para el emulador de Android usar: flutter run --dart-define=API_URL=http://10.0.2.2:5000
    return 'http://127.0.0.1:5000';
  }

  static const String nombreSesion = 'kimuka_sesion_activa';
  static const String usuarioLogueado = 'usuarioLogueado';
  static const String tokenKey = 'token';
}