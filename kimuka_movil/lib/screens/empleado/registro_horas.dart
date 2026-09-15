import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/jornada.dart';
import '../../state/auth_provider.dart';
import '../../state/horas_provider.dart';
import '../../theme/app_theme.dart';
import '../common/home_shell.dart';

class RegistroHorasScreen extends StatefulWidget {
  const RegistroHorasScreen({super.key});

  @override
  State<RegistroHorasScreen> createState() => _RegistroHorasScreenState();
}

class _RegistroHorasScreenState extends State<RegistroHorasScreen> {
  bool _enviando = false;
  late Timer _relojTimer;
  DateTime _ahora = DateTime.now();
  Jornada? _activa;

  @override
  void initState() {
    super.initState();
    _buscarActiva();
    // Actualiza el reloj y el contador cada segundo
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
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      final api = context.read<ApiClient>();
      final jornadasRaw = await api.listarJornadas();

      if (!mounted) return;
      final lista = jornadasRaw
          .map((j) => Jornada.fromJson(j as Map<String, dynamic>))
          .where((j) => j.activa && j.idUsuarioEmpleado == user.idUsuario)
          .toList();

      if (lista.isNotEmpty) {
        setState(() {
          _activa = lista.first;
        });
        // Sincronizar también con el HorasProvider para el dashboard
        context.read<HorasProvider>().fetchMisHoras(user.idUsuario);
      }
    } catch (_) {}
  }

  // Calcula horas, minutos y segundos transcurridos
  String _tiempoTranscurrido(Jornada activa) {
    try {
      final hInicioStr = activa.hInicio;
      if (hInicioStr == null || hInicioStr.isEmpty) return '00:00:00';

      final partes = hInicioStr.split(':');
      final hora = int.parse(partes[0]);
      final minuto = int.parse(partes[1]);
      final segundo = partes.length > 2 ? int.parse(partes[2].split('.')[0]) : 0;

      final inicio = DateTime(
        _ahora.year,
        _ahora.month,
        _ahora.day,
        hora,
        minuto,
        segundo,
      );

      final diff = _ahora.difference(inicio);
      if (diff.isNegative) return '00:00:00';

      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    } catch (_) {
      return 'En curso';
    }
  }

  Future<void> _ingresarAlSistema() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    // Si ya tiene una jornada activa iniciada, simplemente lo lleva al menú
    if (_activa != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeShell(user: user)),
        (_) => false,
      );
      return;
    }

    setState(() => _enviando = true);
    final api = context.read<ApiClient>();

    try {
      final jornadas = await api.listarJornadas();
      final activa = jornadas
          .map((j) => Jornada.fromJson(j as Map<String, dynamic>))
          .where((j) => j.activa && j.idUsuarioEmpleado == user.idUsuario)
          .firstOrNull;

      if (activa == null) {
        await api.crearJornada({
          'idUsuario_Empleado': user.idUsuario,
          'fecha': DateFormat('yyyy-MM-dd').format(_ahora),
          'hInicio': DateFormat('HH:mm:ss').format(_ahora),
        });
      }

      if (!mounted) return;
      await context.read<HorasProvider>().fetchMisHoras(user.idUsuario);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeShell(user: user)),
        (_) => false,
      );
    } on ApiException catch (e) {
      _mostrar(e.message);
      if (e.message.toLowerCase().contains('activa')) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeShell(user: user)),
          (_) => false,
        );
      }
    } catch (_) {
      _mostrar('No se pudo conectar con el servidor.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final nombre = (user?.nombre ?? 'EMPLEADO').toUpperCase();

    final horaFormateada = DateFormat('hh:mm a').format(_ahora).toLowerCase();
    final fechaFormateada = DateFormat('dd/MM/yyyy').format(_ahora);

    final tieneActiva = _activa != null;

    // Texto de hora de inicio (si ya está iniciada, se congela en la hora de entrada real)
    final String horaInicioMostrada;
    if (tieneActiva && _activa!.hInicio != null) {
      final h = _activa!.hInicio!;
      horaInicioMostrada = h.length > 5 ? h.substring(0, 5) : h;
    } else {
      horaInicioMostrada = horaFormateada;
    }

    final String fechaMostrada = tieneActiva && _activa!.fecha != null
        ? _activa!.fecha!
        : fechaFormateada;

    // Si ya inició jornada, muestra el contador en vivo
    final String textoBoton = tieneActiva
        ? 'Tiempo en turno: ${_tiempoTranscurrido(_activa!)}'
        : 'Ingresar Al Sistema';

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
              'Kimuka - Hora De Inicio',
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final esAncho = constraints.maxWidth > 550;
                    return Flex(
                      direction: esAncho ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Círculo con icono de reloj
                        Container(
                          width: esAncho ? 180 : 140,
                          height: esAncho ? 180 : 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.bgInput,
                            border: Border.all(color: AppTheme.borderColor, width: 2),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            size: 76,
                            color: AppTheme.acento,
                          ),
                        ),
                        if (esAncho) const SizedBox(width: 44) else const SizedBox(height: 28),

                        // Columna de datos
                        Expanded(
                          flex: esAncho ? 1 : 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                nombre,
                                textAlign: esAncho ? TextAlign.start : TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'HORA DE INICIO (AUTOMÁTICA COLOMBIA)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textoSecundario,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _campoBloqueado(
                                texto: horaInicioMostrada,
                                icono: Icons.access_time,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'DÍA DE JORNADA (AUTOMÁTICO)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textoSecundario,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _campoBloqueado(
                                texto: fechaMostrada,
                                icono: Icons.calendar_today_outlined,
                              ),
                              const SizedBox(height: 24),

                              // Botón blanco con el contador activo
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: _enviando ? null : _ingresarAlSistema,
                                child: _enviando
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        textoBoton,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
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
          Text(texto, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
          Icon(icono, color: AppTheme.textoSecundario, size: 16),
        ],
      ),
    );
  }
}