import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/jornada.dart';
import '../../state/auth_provider.dart';
import '../../state/horas_provider.dart';
import '../../theme/app_theme.dart';

class RegistroHorasScreen extends StatefulWidget {
  const RegistroHorasScreen({super.key});

  @override
  State<RegistroHorasScreen> createState() => _RegistroHorasScreenState();
}

class _RegistroHorasScreenState extends State<RegistroHorasScreen> {
  bool _enviando = false;
  Jornada? _activa;

  @override
  void initState() {
    super.initState();
    _buscarActiva();
  }

  Future<void> _buscarActiva() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        await context.read<HorasProvider>().fetchMisHoras(user.idUsuario);
      }
      if (!mounted) return;

      final jornadas = context.read<HorasProvider>().jornadas;
      setState(() {
        _activa = jornadas.where((j) => j.activa).firstOrNull;
      });
    } catch (_) {}
  }

  Future<void> _iniciar() async {
    if (_activa != null) {
      _mostrar('Ya tienes una jornada activa. Finalízala antes de iniciar otra.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) throw ApiException('Sesión no válida');
      final ahora = DateTime.now();

      final exito = await context.read<HorasProvider>().crearJornada({
        'idUsuario_Empleado': user.idUsuario,
        'fecha': DateFormat('yyyy-MM-dd').format(ahora),
        'hInicio': DateFormat('HH:mm').format(ahora),
      }, user.idUsuario);

      if (exito) {
        _mostrar('Jornada iniciada correctamente.');
        await _buscarActiva();
      } else {
        final errorMsg = context.read<HorasProvider>().error;
        _mostrar(errorMsg ?? 'No se pudo iniciar la jornada.');
      }
    } on ApiException catch (e) {
      _mostrar(e.message);
    } catch (_) {
      _mostrar('No se pudo conectar con el servidor');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _finalizar() async {
    setState(() => _enviando = true);
    try {
      final api = context.read<ApiClient>();
      final user = context.read<AuthProvider>().user;
      final ahora = DateTime.now();

      await api.finalizarJornada(_activa!.idJornada, {
        'hFin': DateFormat('HH:mm').format(ahora),
      });

      if (user != null) {
        await context.read<HorasProvider>().fetchMisHoras(user.idUsuario);
      }

      _mostrar('Jornada finalizada correctamente.');
      await _buscarActiva();
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
    final nombre =
    (context.watch<AuthProvider>().user?.nombre ?? 'EMPLEADO').toUpperCase();
    final ahora = DateTime.now();
    final fecha = DateFormat('yyyy-MM-dd').format(ahora);
    final hora = DateFormat('HH:mm').format(ahora);

    return Scaffold(
      backgroundColor: AppTheme.bgMain, // Soluciona el fondo blanco
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
            Text(
              nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary, // Blanco nítido sin subrayado
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Fecha',
                      style: TextStyle(color: AppTheme.textoSecundario),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fecha,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Hora actual',
                      style: TextStyle(color: AppTheme.textoSecundario),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hora,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.acento,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_activa != null)
                      Column(
                        children: [
                          Chip(
                            avatar: const Icon(Icons.play_circle,
                                color: AppTheme.exito, size: 18),
                            label: const Text('Jornada en curso'),
                            backgroundColor: AppTheme.exito.withValues(alpha: 0.15),
                            side: const BorderSide(color: AppTheme.exito),
                            labelStyle: const TextStyle(color: AppTheme.exito),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Entrada: ${_activa!.hInicio}',
                            style: const TextStyle(
                                color: AppTheme.textoSecundario),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _enviando ? null : _finalizar,
                            icon: const Icon(Icons.stop_circle),
                            label: const Text('Finalizar jornada'),
                          ),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _enviando ? null : _iniciar,
                        icon: const Icon(Icons.login),
                        label: const Text('Registrar entrada de jornada'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Al cerrar sesión podrás registrar tu hora de salida.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textoSecundario,
                fontSize: 14,
                decoration: TextDecoration.none, // Elimina el subrayado amarillo
              ),
            ),
          ],
        ),
      ),
    );
  }
}
