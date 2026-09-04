import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'inventario.dart';
import 'mis_horas.dart';
import 'registro_horas.dart';
import 'tareas.dart';

class DashboardEmpleado extends StatelessWidget {
  const DashboardEmpleado({super.key});

  void _ir(BuildContext context, Widget pantalla) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
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
          icono: Icons.login,
          titulo: 'Registrar Entrada',
          subtitulo: 'Inicia tu jornada de trabajo',
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
      ],
    );
  }
}
