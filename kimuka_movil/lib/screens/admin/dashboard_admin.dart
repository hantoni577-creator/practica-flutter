import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'admin_horas.dart';
import 'admin_pagos.dart';
import 'aprobar_pago.dart';
import 'asignar_insumos.dart';
import 'gestion_empleados.dart';
import 'gestion_pedidos.dart';
import 'materia_prima.dart';
import 'panel_reportes.dart';
import 'registro_personal.dart';
import 'tareas_admin.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({
    super.key,
    required this.alIr,
    required this.alCerrarSesion,
  });

  final void Function(Widget pantalla) alIr;
  final VoidCallback alCerrarSesion;

  void _ir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final nombre =
        (context.watch<AuthProvider>().user?.nombre ?? 'ADMIN').toUpperCase();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.checkroom, size: 64, color: AppTheme.acento),
        const SizedBox(height: 8),
        Text(
          'Bienvenido, $nombre',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primario,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Gestiona el personal, inventario, pedidos, pagos y reportes.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textoSecundario),
        ),
        const SizedBox(height: 24),
        const TituloSeccion(texto: 'Módulos de administración'),
        ItemMenu(
          icono: Icons.person_add_alt,
          titulo: 'Registro de personal',
          subtitulo: 'Crear nuevos usuarios del sistema',
          onTap: () => _ir(context, const RegistroPersonalScreen()),
        ),
        ItemMenu(
          icono: Icons.groups,
          titulo: 'Gestión de empleados',
          subtitulo: 'Listar, editar y desactivar empleados',
          onTap: () => _ir(context, const GestionEmpleadosScreen()),
        ),
        ItemMenu(
          icono: Icons.inventory_2_outlined,
          titulo: 'Materia prima',
          subtitulo: 'Administrar insumos del inventario',
          onTap: () => _ir(context, const MateriaPrimaScreen()),
        ),
        ItemMenu(
          icono: Icons.shopping_cart,
          titulo: 'Gestión de pedidos',
          subtitulo: 'Crear y actualizar pedidos de producción',
          onTap: () => _ir(context, const GestionPedidosScreen()),
        ),
        ItemMenu(
          icono: Icons.schedule,
          titulo: 'Horas de empleados',
          subtitulo: 'Consultar jornadas registradas',
          onTap: () => _ir(context, const AdminHorasScreen()),
        ),
        ItemMenu(
          icono: Icons.payments,
          titulo: 'Pagos',
          subtitulo: 'Consultar pagos realizados',
          onTap: () => _ir(context, const AdminPagosScreen()),
        ),
        ItemMenu(
          icono: Icons.task_alt,
          titulo: 'Aprobar pago',
          subtitulo: 'Registrar y aprobar un pago a empleado',
          onTap: () => _ir(context, const AprobarPagoScreen()),
        ),
        ItemMenu(
          icono: Icons.assignment_ind,
          titulo: 'Asignar insumos',
          subtitulo: 'Asignar materia prima a empleados',
          onTap: () => _ir(context, const AsignarInsumosScreen()),
        ),
        ItemMenu(
          icono: Icons.assignment,
          titulo: 'Tareas de empleados',
          subtitulo: 'Consultar tareas y estados',
          onTap: () => _ir(context, const TareasAdminScreen()),
        ),
        ItemMenu(
          icono: Icons.bar_chart,
          titulo: 'Panel de reportes',
          subtitulo: 'Reportes y exportación a Excel',
          onTap: () => _ir(context, const PanelReportesScreen()),
        ),
        const SizedBox(height: 16),
        const Divider(),
        ItemMenu(
          icono: Icons.logout,
          titulo: 'Cerrar sesión',
          onTap: alCerrarSesion,
        ),
      ],
    );
  }
}
