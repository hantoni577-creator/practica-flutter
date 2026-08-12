import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import 'admin_horas.dart';
import 'admin_pagos.dart';
import 'aprobar_pago.dart';
import 'asignar_insumos.dart';
import 'dashboard_admin.dart';
import 'gestion_empleados.dart';
import 'gestion_pedidos.dart';
import 'materia_prima.dart';
import 'panel_reportes.dart';
import 'registro_personal.dart';
import 'reporte_horas.dart';
import 'reporte_materias.dart';
import 'reporte_produccion.dart';
import 'reporte_trabajos.dart';
import 'tareas_admin.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.user});

  final dynamic user;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  void _ir(Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  Future<void> _cerrarSesion() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.user?.nombre ?? 'ADMIN';
    return Scaffold(
      appBar: AppBar(title: const Text('Administración Kimuka')),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                accountEmail: const Text('Administrador del sistema'),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF1B1B2F),
                  child: Icon(Icons.admin_panel_settings),
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B1B2F),
                ),
              ),
              _item(Icons.dashboard_outlined, 'Dashboard', () {
                Navigator.of(context).pop();
              }),
              _item(Icons.person_add_alt, 'Registro de personal', () =>
                  _ir(const RegistroPersonalScreen())),
              _item(Icons.groups, 'Gestión de empleados', () =>
                  _ir(const GestionEmpleadosScreen())),
              _item(Icons.inventory_2_outlined, 'Materia prima', () =>
                  _ir(const MateriaPrimaScreen())),
              _item(Icons.shopping_cart, 'Gestión de pedidos', () =>
                  _ir(const GestionPedidosScreen())),
              _item(Icons.schedule, 'Horas de empleados', () =>
                  _ir(const AdminHorasScreen())),
              _item(Icons.payments, 'Pagos', () =>
                  _ir(const AdminPagosScreen())),
              _item(Icons.task_alt, 'Aprobar pago', () =>
                  _ir(const AprobarPagoScreen())),
              _item(Icons.assignment_ind, 'Asignar insumos', () =>
                  _ir(const AsignarInsumosScreen())),
              _item(Icons.assignment, 'Tareas de empleados', () =>
                  _ir(const TareasAdminScreen())),
              _item(Icons.bar_chart, 'Panel de reportes', () =>
                  _ir(const PanelReportesScreen())),
              _item(Icons.query_stats, 'Reporte horas', () =>
                  _ir(const ReporteHorasScreen())),
              _item(Icons.work_outline, 'Reporte trabajos', () =>
                  _ir(const ReporteTrabajosScreen())),
              _item(Icons.factory_outlined, 'Reporte producción', () =>
                  _ir(const ReporteProduccionScreen())),
              _item(Icons.category_outlined, 'Reporte materias primas', () =>
                  _ir(const ReporteMateriasScreen())),
              const Divider(),
              _item(Icons.logout, 'Cerrar sesión', _cerrarSesion),
            ],
          ),
        ),
      ),
      body: DashboardAdmin(
        alIr: _ir,
        alCerrarSesion: _cerrarSesion,
      ),
    );
  }

  Widget _item(IconData icono, String titulo, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icono, color: const Color(0xFF1B1B2F)),
      title: Text(titulo),
      onTap: onTap,
    );
  }
}
