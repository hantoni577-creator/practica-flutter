import 'package:flutter/material.dart';

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
  int _indice = 0;

  static const _titulos = [
    'Inicio',
    'Registrar Horas',
    'Mis Horas',
    'Inventario',
    'Mis Tareas',
  ];

  late final List<Widget> _pantallas = [
    const DashboardEmpleado(),
    const RegistroHorasScreen(),
    const MisHorasScreen(),
    const InventarioScreen(),
    const TareasScreen(),
  ];

  void _cerrarSesion() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CierreSesionEmpleadoScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.user?.nombre ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_indice]),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'salir') _cerrarSesion();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'salir',
                enabled: false,
                child: Text(
                  nombre.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'salir',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _pantallas[_indice],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.login_outlined),
            label: 'Registrar',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            label: 'Mis Horas',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            label: 'Tareas',
          ),
        ],
      ),
    );
  }
}
