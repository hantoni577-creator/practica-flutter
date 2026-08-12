import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import 'reporte_horas.dart';
import 'reporte_materias.dart';
import 'reporte_produccion.dart';
import 'reporte_trabajos.dart';

class PanelReportesScreen extends StatelessWidget {
  const PanelReportesScreen({super.key});

  void _ir(BuildContext context, Widget pantalla) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de reportes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Consulta y exporta los reportes del sistema a Excel.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          ItemMenu(
            icono: Icons.query_stats,
            titulo: 'Reporte horas trabajadas',
            subtitulo: 'Jornadas por empleado, mes y año',
            onTap: () => _ir(context, const ReporteHorasScreen()),
          ),
          ItemMenu(
            icono: Icons.work_outline,
            titulo: 'Reporte trabajos realizados',
            subtitulo: 'Asignaciones de insumos por empleado',
            onTap: () => _ir(context, const ReporteTrabajosScreen()),
          ),
          ItemMenu(
            icono: Icons.factory_outlined,
            titulo: 'Reporte producción',
            subtitulo: 'Órdenes de producción por cliente',
            onTap: () => _ir(context, const ReporteProduccionScreen()),
          ),
          ItemMenu(
            icono: Icons.category_outlined,
            titulo: 'Reporte materias primas',
            subtitulo: 'Inventario de insumos por categoría',
            onTap: () => _ir(context, const ReporteMateriasScreen()),
          ),
        ],
      ),
    );
  }
}
