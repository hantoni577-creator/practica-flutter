import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/session_manager.dart';
import 'state/auth_provider.dart';
import 'state/horas_provider.dart';
import 'state/inventario_provider.dart';
import 'state/pagos_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de SharedPreferences y SessionManager
  final prefs = await SharedPreferences.getInstance();
  final session = SessionManager(prefs);
  final api = ApiClient(session);

  runApp(
    MultiProvider(
      providers: [
        Provider<SessionManager>.value(value: session),
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(session: session, api: api),
        ),
        ChangeNotifierProvider(
          create: (_) => HorasProvider(api),
        ),
        ChangeNotifierProvider(
          create: (_) => PagosProvider(api),
        ),
        ChangeNotifierProvider(
          create: (_) => InventarioProvider(api),
        ),
      ],
      child: KimukaApp(session: session, api: api),
    ),
  );
}