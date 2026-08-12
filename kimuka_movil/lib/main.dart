import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/session_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final session = SessionManager(prefs);
  final api = ApiClient(session);
  runApp(KimukaApp(session: session, api: api));
}
