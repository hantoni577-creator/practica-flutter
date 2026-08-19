import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _urlPersonalizada =
  String.fromEnvironment('API_URL', defaultValue: '');

  static String get baseUrl {
    if (_urlPersonalizada.isNotEmpty) return _urlPersonalizada;

    // Si estás ejecutando en navegador Web o Windows
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    }

    // Si estás en emulador Android
    return 'http://10.0.2.2:5000';
  }

  static const String nombreSesion = 'kimuka_sesion_activa';
  static const String usuarioLogueado = 'usuarioLogueado';
  static const String tokenKey = 'token';
}