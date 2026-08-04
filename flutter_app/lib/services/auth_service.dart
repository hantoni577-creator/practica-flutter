import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/constants.dart';

class AuthService {

  final storage = const FlutterSecureStorage();

  Future<bool> login(

      String email,

      String password,

      ) async {

    final response = await http.post(

      Uri.parse("${Constants.baseUrl}/auth/login"),

      headers: {

        "Content-Type": "application/json"

      },

      body: jsonEncode({

        "email": email,

        "password": password

      }),

    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      await storage.write(

        key: "token",

        value: data["token"],

      );

      return true;

    }

    return false;

  }

  Future<bool> register(

      String nombre,

      String email,

      String password,

      ) async {

    final response = await http.post(

      Uri.parse("${Constants.baseUrl}/auth/register"),

      headers: {

        "Content-Type": "application/json"

      },

      body: jsonEncode({

        "nombre": nombre,

        "email": email,

        "password": password

      }),

    );

    return response.statusCode == 201;

  }

  Future<String?> getToken() async {

    return await storage.read(

      key: "token",

    );

  }

  Future<void> logout() async {

    await storage.delete(

      key: "token",

    );

  }

}