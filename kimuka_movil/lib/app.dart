import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/session_manager.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/recuperar_contrasena_screen.dart';
import 'screens/common/splash_screen.dart';
import 'state/auth_provider.dart';
import 'theme/app_theme.dart';

class KimukaApp extends StatelessWidget {
  const KimukaApp({super.key, required this.session, required this.api});

  final SessionManager session;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: session),
        Provider.value(value: api),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(session: session, api: api)..init(),
        ),
      ],
      child: MaterialApp(
        title: 'Kimuka',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
        routes: {
          LoginScreen.ruta: (_) => const LoginScreen(),
          RecuperarContrasenaScreen.ruta: (_) =>
              const RecuperarContrasenaScreen(),
        },
      ),
    );
  }
}
