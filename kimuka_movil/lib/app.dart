import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/session_manager.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/recuperar_contrasena_screen.dart';
import 'screens/common/splash_screen.dart';
import 'theme/app_theme.dart';

class KimukaApp extends StatelessWidget {
  const KimukaApp({super.key, required this.session, required this.api});

  final SessionManager session;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    // Nota: session, api y AuthProvider ya se registran una sola vez
    // en main.dart (MultiProvider raíz), por lo que aquí no se vuelven
    // a declarar para evitar instancias duplicadas.
    return MaterialApp(
      title: 'Kimuka',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      routes: {
        LoginScreen.ruta: (_) => const LoginScreen(),
        RecuperarContrasenaScreen.ruta: (_) =>
            const RecuperarContrasenaScreen(),
      },
    );
  }
}
