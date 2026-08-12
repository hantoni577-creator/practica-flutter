class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const String nombreSesion = 'kimuka_sesion_activa';
  static const String usuarioLogueado = 'usuarioLogueado';
  static const String tokenKey = 'token';
}
