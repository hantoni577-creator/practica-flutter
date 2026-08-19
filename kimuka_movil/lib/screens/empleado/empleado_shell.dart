import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../state/horas_provider.dart';
import '../../state/inventario_provider.dart';

import 'cierre_empleado.dart';
import 'dashboard_empleado.dart';
import 'inventario.dart';
import 'mis_horas.dart';
import 'registro_horas.dart';
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
        // Solución al Error 1: pasar el idUsuario requerido
        context.read<HorasProvider>().fetchMisHoras(user.idUsuario);
      }
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
    final nombre = widget.user?.nombre ?? 'EMPLEADO';
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Empleado - Kimuka')),
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
                accountEmail: const Text('Operario / Empleado'),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF1B1B2F),
                  child: Icon(Icons.person),
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B1B2F),
                ),
              ),
              _item(Icons.dashboard_outlined, 'Inicio', () {
                Navigator.of(context).pop();
              }),
              _item(Icons.schedule, 'Mis Horas', () =>
                  _ir(const MisHorasScreen())),
              _item(Icons.more_time, 'Registrar Horas', () =>
                  _ir(const RegistroHorasScreen())),
              _item(Icons.task_alt, 'Mis Tareas', () =>
                  _ir(const TareasScreen())),
              _item(Icons.inventory_2_outlined, 'Inventario', () =>
                  _ir(const InventarioScreen())),
              // Solución al Error 2: Nombre de clase real en cierre_empleado.dart
              _item(Icons.lock_clock, 'Cierre de Jornada', () {
                Navigator.of(context).pop();
              }),
              const Divider(),
              _item(Icons.logout, 'Cerrar sesión', _cerrarSesion),
            ],
          ),
        ),
      ),
      // Solución a los Errores 3 y 4: DashboardEmpleado se instancia directamente
      body: const DashboardEmpleado(),
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
