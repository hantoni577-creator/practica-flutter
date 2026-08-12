import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/jornada.dart';
import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class CierreSesionEmpleadoScreen extends StatefulWidget {
  const CierreSesionEmpleadoScreen({super.key});

  @override
  State<CierreSesionEmpleadoScreen> createState() =>
      _CierreSesionEmpleadoScreenState();
}

class _CierreSesionEmpleadoScreenState
    extends State<CierreSesionEmpleadoScreen> {
  bool _cargando = true;
  bool _enviando = false;
  Jornada? _activa;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscarActiva();
  }

  Future<void> _buscarActiva() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final user = context.read<AuthProvider>().user;
      if (user == null) {
        await _cerrarSesion();
        return;
      }
      final jornadas = await api.listarJornadas();
      if (!mounted) return;
      setState(() {
        _activa = jornadas
            .map((j) => Jornada.fromJson(j as Map<String, dynamic>))
            .where((j) => j.activa)
            .firstOrNull;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo verificar tu jornada activa.';
        _cargando = false;
      });
    }
  }

  Future<void> _finalizarYSalir() async {
    setState(() => _enviando = true);
    try {
      final api = context.read<ApiClient>();
      if (_activa != null) {
        final ahora = DateTime.now();
        await api.finalizarJornada(_activa!.idJornada, {
          'hFin': DateFormat('HH:mm').format(ahora),
        });
      }
      if (!mounted) return;
      await _cerrarSesion();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar con el servidor')),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cerrar sesión')),
        body: const Cargando(),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cerrar sesión')),
        body: VistaError(mensaje: _error!, onReintentar: _buscarActiva),
      );
    }
    final nombre =
        (context.read<AuthProvider>().user?.nombre ?? 'EMPLEADO').toUpperCase();
    final ahora = DateTime.now();
    final horaSalida = DateFormat('HH:mm').format(ahora);
    final fechaHoy = DateFormat('yyyy-MM-dd').format(ahora);
    return Scaffold(
      appBar: AppBar(title: const Text('Cerrar sesión')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primario,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Hora de salida',
                    style: TextStyle(color: AppTheme.textoSecundario),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    horaSalida,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.acento,
                    ),
                  ),
                  Text(
                    fechaHoy,
                    style: const TextStyle(color: AppTheme.textoSecundario),
                  ),
                  const SizedBox(height: 16),
                  if (_activa != null)
                    const Text(
                      'Se registrará la hora de salida de tu jornada activa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textoSecundario),
                    )
                  else
                    const Text(
                      'No tienes una jornada activa. La sesión se cerrará sin registrar salida.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textoSecundario),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _enviando ? null : _finalizarYSalir,
                    icon: const Icon(Icons.logout),
                    label: const Text('Finalizar jornada y cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
