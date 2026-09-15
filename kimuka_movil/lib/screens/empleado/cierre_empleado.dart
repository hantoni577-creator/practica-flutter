import 'dart:async';
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
  late Timer _relojTimer;
  DateTime _ahora = DateTime.now();

  @override
  void initState() {
    super.initState();
    _buscarActiva();
    _relojTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _ahora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _relojTimer.cancel();
    super.dispose();
  }

  Future<void> _buscarActiva() async {
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
            .where((j) => j.activa && j.idUsuarioEmpleado == user.idUsuario)
            .firstOrNull;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _finalizarYSalir() async {
    setState(() => _enviando = true);
    try {
      final api = context.read<ApiClient>();
      if (_activa != null) {
        await api.finalizarJornada(_activa!.idJornada, {
          'hFin': DateFormat('HH:mm:ss').format(_ahora),
        });
      }
      if (!mounted) return;
      await _cerrarSesion();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _enviando = false);
        await _cerrarSesion();
      }
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
      return const Scaffold(
        backgroundColor: AppTheme.bgMain,
        body: Cargando(),
      );
    }

    final horaFinFormateada =
        DateFormat('hh:mm a').format(_ahora).toLowerCase();
    final fechaHoyFormateada = DateFormat('dd/MM/yyyy').format(_ahora);

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.checkroom, color: AppTheme.acento, size: 22),
            SizedBox(width: 8),
            Text(
              'Kimuka - Cierre de Jornada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Card(
              color: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final esAncho = constraints.maxWidth > 550;
                    return Flex(
                      direction: esAncho ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icono circular estilizado
                        Container(
                          width: esAncho ? 180 : 140,
                          height: esAncho ? 180 : 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.bgInput,
                            border: Border.all(
                                color: AppTheme.borderColor, width: 2),
                          ),
                          child: const Icon(
                            Icons.watch_later_outlined,
                            size: 76,
                            color: Color(0xFFE74C3C),
                          ),
                        ),
                        if (esAncho)
                          const SizedBox(width: 44)
                        else
                          const SizedBox(height: 28),

                        // Formulario de salida
                        Expanded(
                          flex: esAncho ? 1 : 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Cierre de Turno',
                                textAlign:
                                    esAncho ? TextAlign.start : TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 20),

                              const Text(
                                'HORA DE FIN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textoSecundario,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _campoBloqueado(
                                  texto: horaFinFormateada,
                                  icono: Icons.access_time),
                              const SizedBox(height: 14),

                              const Text(
                                'FECHA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textoSecundario,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _campoBloqueado(
                                  texto: fechaHoyFormateada,
                                  icono: Icons.calendar_today_outlined),
                              const SizedBox(height: 24),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE74C3C),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25)),
                                  elevation: 2,
                                ),
                                onPressed: _enviando ? null : _finalizarYSalir,
                                child: _enviando
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Text(
                                        'Registrar Salida y Salir',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoBloqueado({required String texto, required IconData icono}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgInput,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(texto,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13)),
          Icon(icono, color: AppTheme.textoSecundario, size: 16),
        ],
      ),
    );
  }
}
