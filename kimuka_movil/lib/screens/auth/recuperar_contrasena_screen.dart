import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../theme/app_theme.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  static const String ruta = '/recuperar';

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState
    extends State<RecuperarContrasenaScreen> {
  final _correo = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    final correo = _correo.text.trim();
    if (correo.isEmpty) {
      _mostrar('Ingresa tu correo electrónico');
      return;
    }
    setState(() => _enviando = true);
    try {
      final api = context.read<ApiClient>();
      await api.recuperarContrasena(correo);
      _mostrar('Solicitud enviada al administrador.');
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      _mostrar(e.message);
    } catch (_) {
      _mostrar('No se pudo conectar con el servidor');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset,
                  size: 64, color: AppTheme.acento),
              const SizedBox(height: 16),
              const Text(
                'Ingresa tu correo corporativo. El administrador recibirá la solicitud para restablecer tu contraseña.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textoSecundario),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _enviar(),
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                child: _enviando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enviar Solicitud'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
