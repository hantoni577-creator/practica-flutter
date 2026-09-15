import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/jornada.dart';
import '../../state/auth_provider.dart';
import '../../state/horas_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'cierre_empleado.dart';
import 'inventario.dart';
import 'mis_horas.dart';
import 'registro_horas.dart';
import 'tareas.dart';

class DashboardEmpleado extends StatefulWidget {
  const DashboardEmpleado({super.key});

  @override
  State<DashboardEmpleado> createState() => _DashboardEmpleadoState();
}

class _DashboardEmpleadoState extends State<DashboardEmpleado> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  String _tiempoTranscurrido(Jornada activa) {
    try {
      final hInicioStr = activa.hInicio;
      if (hInicioStr == null || hInicioStr.isEmpty) return 'En curso';

      final ahora = DateTime.now();
      final partes = hInicioStr.split(':');
      final hora = int.parse(partes[0]);
      final minuto = int.parse(partes[1]);
      final segundo = partes.length > 2 ? int.parse(partes[2].split('.')[0]) : 0;

      final inicio = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        hora,
        minuto,
        segundo,
      );

      final diff = ahora.difference(inicio);
      if (diff.isNegative) return '00:00:00';

      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    } catch (_) {
      return 'En curso';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final jornadas = context.watch<HorasProvider>().jornadas;

    final activa = jornadas
        .where((j) => j.activa && (user == null || j.idUsuarioEmpleado == user.idUsuario))
        .firstOrNull;

    final tiempoEnVivo = activa != null ? _tiempoTranscurrido(activa) : null;

    final String horaInicioSegura = activa?.hInicio ?? '';
    final String horaEntradaTexto = horaInicioSegura.length > 5
        ? horaInicioSegura.substring(0, 5)
        : horaInicioSegura;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.checkroom, size: 64, color: AppTheme.acento),
        const SizedBox(height: 8),
        const Text(
          'Bienvenido a Kimuka',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Gestiona tu jornada laboral, consulta tus horas e insumos asignados.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textoSecundario),
        ),
        const SizedBox(height: 24),
        ItemMenu(
          icono: Icons.timer_outlined,
          titulo: activa != null
              ? 'Tiempo en Turno: $tiempoEnVivo'
              : 'Jornada Iniciada',
          subtitulo: activa != null
              ? 'Entrada registrada a las $horaEntradaTexto'
              : 'Tu tiempo se registra automáticamente al acceder',
          onTap: () => _ir(context, const RegistroHorasScreen()),
        ),
        ItemMenu(
          icono: Icons.schedule,
          titulo: 'Mis Horas',
          subtitulo: 'Historial de jornadas y pago',
          onTap: () => _ir(context, const MisHorasScreen()),
        ),
        ItemMenu(
          icono: Icons.inventory_2_outlined,
          titulo: 'Inventario',
          subtitulo: 'Materia prima disponible',
          onTap: () => _ir(context, const InventarioScreen()),
        ),
        ItemMenu(
          icono: Icons.task_alt,
          titulo: 'Mis Tareas',
          subtitulo: 'Insumos asignados para trabajar',
          onTap: () => _ir(context, const TareasScreen()),
        ),
        ItemMenu(
          icono: Icons.lock_clock,
          titulo: 'Cierre de Jornada',
          subtitulo: 'Finaliza tu jornada activa',
          onTap: () => _ir(context, const CierreSesionEmpleadoScreen()),
        ),
      ],
    );
  }
}