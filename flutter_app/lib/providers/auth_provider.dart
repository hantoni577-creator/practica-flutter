import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {

  final AuthService _service = AuthService();

  bool _logged = false;

  bool get logged => _logged;

  Future<void> login(

      String email,

      String password,

      ) async {

    _logged = await _service.login(

      email,

      password,

    );

    notifyListeners();

  }

  Future<void> logout() async {

    await _service.logout();

    _logged = false;

    notifyListeners();

  }

}