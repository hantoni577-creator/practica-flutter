import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../state/horas_provider.dart';
import '../../state/inventario_provider.dart';
import '../../state/pagos_provider.dart';
import '../../theme/app_theme.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PagosProvider>().fetchPagosPendientes();
      context.read<HorasProvider>().fetchHorasAdmin();
      context.read<InventarioProvider>().fetchInventario();
    });
  }

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
    final nombre = (widget.user?.nombre ?? 'ADMIN').toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Administración Kimuka')),
      drawer: Drawer(
        backgroundColor: AppTheme.bgCard,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black, // Contraste nítido sobre el dorado
                  ),
                ),
                accountEmail: const Text(
                  'Administrador del sistema',
                  style: TextStyle(
                    color: Color(0xFF2C2C2C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.black,
                  foregroundColor: AppTheme.acento,
                  child: Icon(Icons.admin_panel_settings, size: 40),
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.acento, // Fondo dorado idéntico al gancho
                ),
              ),
              _item(Icons.grid_view_outlined, 'Dashboard', () {
                Navigator.of(context).pop();
              }),
              _item(Icons.person_add_alt, 'Registro de personal', () {
                Navigator.of(context).pop();
                _ir(const RegistroPersonalScreen());
              }),
              _item(Icons.groups_outlined, 'Gestión de empleados', () {
                Navigator.of(context).pop();
                _ir(const GestionEmpleadosScreen());
              }),
              _item(Icons.archive_outlined, 'Materia prima', () {
                Navigator.of(context).pop();
                _ir(const MateriaPrimaScreen());
              }),
              _item(Icons.shopping_cart_outlined, 'Gestión de pedidos', () {
                Navigator.of(context).pop();
                _ir(const GestionPedidosScreen());
              }),
              _item(Icons.access_time, 'Horas de empleados', () {
                Navigator.of(context).pop();
                _ir(const AdminHorasScreen());
              }),
              _item(Icons.payments_outlined, 'Pagos', () {
                Navigator.of(context).pop();
                _ir(const AdminPagosScreen());
              }),
              _item(Icons.check_circle_outline, 'Aprobar pago', () {
                Navigator.of(context).pop();
                _ir(const AprobarPagoScreen());
              }),
              _item(Icons.assignment_ind_outlined, 'Asignar insumos', () {
                Navigator.of(context).pop();
                _ir(const AsignarInsumosScreen());
              }),
              _item(Icons.assignment_outlined, 'Tareas de empleados', () {
                Navigator.of(context).pop();
                _ir(const TareasAdminScreen());
              }),
              _item(Icons.bar_chart_outlined, 'Panel de reportes', () {
                Navigator.of(context).pop();
                _ir(const PanelReportesScreen());
              }),
              _item(Icons.query_stats, 'Reporte horas', () {
                Navigator.of(context).pop();
                _ir(const ReporteHorasScreen());
              }),
              _item(Icons.work_outline, 'Reporte trabajos', () {
                Navigator.of(context).pop();
                _ir(const ReporteTrabajosScreen());
              }),
              _item(Icons.factory_outlined, 'Reporte producción', () {
                Navigator.of(context).pop();
                _ir(const ReporteProduccionScreen());
              }),
              _item(Icons.category_outlined, 'Reporte materias primas', () {
                Navigator.of(context).pop();
                _ir(const ReporteMateriasScreen());
              }),
              const Divider(color: AppTheme.borderColor),
              _item(
                Icons.logout,
                'Cerrar sesión',
                () {
                  Navigator.of(context).pop();
                  _cerrarSesion();
                },
                color: const Color(0xFFE74C3C),
              ),
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

  Widget _item(IconData icono, String titulo, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icono, color: color ?? Colors.white, size: 24),
      title: Text(
        titulo,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}