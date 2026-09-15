import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../state/horas_provider.dart';
import '../../state/inventario_provider.dart';
import '../../theme/app_theme.dart';

import 'cierre_empleado.dart';
import 'dashboard_empleado.dart';
import 'inventario.dart';
import 'mis_horas.dart';
import 'tareas.dart';

class EmpleadoShell extends StatefulWidget {
  const EmpleadoShell({super.key, required this.user});

  final dynamic user;

  @override
  State<EmpleadoShell> createState() => _EmpleadoShellState();
}

class _EmpleadoShellState extends State<EmpleadoShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user ?? widget.user;
      if (user != null) {
        context.read<HorasProvider>().fetchMisHoras(user.idUsuario);
      }
      context.read<InventarioProvider>().fetchInventario();
    });
  }

  void _ir(Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  void _irACierreDeJornada() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CierreSesionEmpleadoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = (widget.user?.nombre ?? 'EMPLEADO').toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Empleado - Kimuka'),
      ),
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
                    color: Colors.black, // Contraste sobre fondo dorado
                  ),
                ),
                accountEmail: const Text(
                  'Operario / Empleado',
                  style: TextStyle(
                    color: Color(0xFF2C2C2C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.black,
                  foregroundColor: AppTheme.acento,
                  child: Icon(Icons.person, size: 40),
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.acento, // Mismo color dorado del gancho
                ),
              ),
              _item(Icons.grid_view_outlined, 'Inicio', () {
                Navigator.of(context).pop();
              }),
              _item(Icons.access_time, 'Mis Horas', () {
                Navigator.of(context).pop();
                _ir(const MisHorasScreen());
              }),
              _item(Icons.check_circle_outline, 'Mis Tareas', () {
                Navigator.of(context).pop();
                _ir(const TareasScreen());
              }),
              _item(Icons.archive_outlined, 'Inventario', () {
                Navigator.of(context).pop();
                _ir(const InventarioScreen());
              }),
              _item(Icons.lock_clock, 'Cierre de Jornada', () {
                Navigator.of(context).pop();
                _irACierreDeJornada();
              }),
              const Divider(color: AppTheme.borderColor),
              _item(Icons.logout, 'Cerrar sesión', () {
                Navigator.of(context).pop();
                _irACierreDeJornada();
              }, color: const Color(0xFFE74C3C)),
            ],
          ),
        ),
      ),
      body: const DashboardEmpleado(),
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
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
