import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/session_manager.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.session, required this.api});

  final SessionManager session;
  final ApiClient api;

  User? _user;
  bool _cargando = false;
  String? _error;

  User? get user => _user;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get logueado => _user != null;

  Future<void> init() async {
    _user = await session.loadUser();
    notifyListeners();
  }

  Future<bool> login(String correo, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final data = await api.login(correo.trim(), password);
      final user = User.fromJson(data);
      await session.saveUser(user);
      _user = user;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e, stack) {
      print('DETALLE ERROR FLUTTER: $e');
      print(stack);
      _error = 'Error: $e';
      return false;
    }finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await session.clear();
    _user = null;
    notifyListeners();
  }
}
