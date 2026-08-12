import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user.dart';

class SessionManager {
  SessionManager(this._prefs);

  final SharedPreferences _prefs;

  String? get token => _prefs.getString(ApiConfig.tokenKey);

  bool get hasSession =>
      (_prefs.getString(ApiConfig.nombreSesion) ?? '').isNotEmpty;

  Future<void> saveUser(User user) async {
    await _prefs.setString(ApiConfig.nombreSesion, user.nombre);
    await _prefs.setString(ApiConfig.usuarioLogueado, jsonEncode(user.toJson()));
    await _prefs.setString(ApiConfig.tokenKey, user.token);
  }

  Future<User?> loadUser() async {
    final raw = _prefs.getString(ApiConfig.usuarioLogueado);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _prefs.remove(ApiConfig.nombreSesion);
    await _prefs.remove(ApiConfig.usuarioLogueado);
    await _prefs.remove(ApiConfig.tokenKey);
  }
}
