import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../auth/login_screen.dart';
import 'home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decidir());
  }

  void _decidir() {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      Navigator.of(context).pushReplacementNamed(LoginScreen.ruta);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeShell(user: auth.user!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.checkroom, size: 80, color: Color(0xFFF39C12)),
            SizedBox(height: 16),
            Text(
              'KIMUKA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B1B2F),
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
