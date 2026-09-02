import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../common/home_shell.dart';
import 'recuperar_contrasena_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String ruta = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correo = TextEditingController();
  final _password = TextEditingController();
  bool _ocultarPass = true;

  @override
  void dispose() {
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_correo.text, _password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeShell(user: auth.user!)),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgMain, // Fondo negro premium
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.checkroom,
                      size: 72, color: AppTheme.acento),
                  const SizedBox(height: 8),
                  const Text(
                    'KIMUKA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary, // Blanco nítido
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Acceso al Sistema',
                    textAlign: TextAlign.center,
                    style:
                    TextStyle(fontSize: 18, color: AppTheme.textoSecundario),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _correo,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textoSecundario),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    obscureText: _ocultarPass,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _ingresar(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textoSecundario),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarPass ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textoSecundario,
                        ),
                        onPressed: () =>
                            setState(() => _ocultarPass = !_ocultarPass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextoErrores(mensaje: auth.error ?? ''),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: auth.cargando ? null : _ingresar,
                    child: auth.cargando
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                        : const Text('Ingresar de Forma Segura'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamed(RecuperarContrasenaScreen.ruta),
                    child: const Text(
                      '¿Problemas para acceder? Recuperar contraseña',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.acento,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
