import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class ApiService {

  static Future<http.Response> post(

      String endpoint,

      Map<String, dynamic> body,

      ) {

    return http.post(

      Uri.parse("${Constants.baseUrl}$endpoint"),

      headers: {

        "Content-Type": "application/json"

      },

      body: body,

    );

  }

}