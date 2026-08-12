import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/usuario.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'editar_empleado.dart';

class GestionEmpleadosScreen extends StatefulWidget {
  const GestionEmpleadosScreen({super.key});

  @override
  State<GestionEmpleadosScreen> createState() => _GestionEmpleadosScreenState();
}

class _GestionEmpleadosScreenState extends State<GestionEmpleadosScreen> {
  late Future<List<Usuario>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Usuario>> _cargar() async {
    final api = context.read<ApiClient>();
    final data = await api.listarUsuarios();
    return data
        .map((u) => Usuario.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  Future<void> _desactivar(Usuario usuario) async {
    final api = context.read<ApiClient>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar usuario'),
        content: Text(
            '¿Desactivar a ${usuario.nombre}? No podrá iniciar sesión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await api.desactivarUsuario(usuario.idUsuario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario desactivado.')),
      );
      setState(() => _futuro = _cargar());
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _editar(Usuario usuario) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditarEmpleadoScreen(usuario: usuario)),
    );
    if (mounted) setState(() => _futuro = _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de empleados')),
      body: FutureBuilder<List<Usuario>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Cargando();
          }
          if (snapshot.hasError) {
            return VistaError(
              mensaje: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Error al cargar los usuarios.',
              onReintentar: () => setState(() => _futuro = _cargar()),
            );
          }
          final usuarios = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _futuro = _cargar()),
            child: usuarios.isEmpty
                ? ListView(children: const [SinDatos()])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: usuarios.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final u = usuarios[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: u.activo
                                ? AppTheme.primario
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.person),
                          ),
                          title: Text(
                            u.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primario,
                            ),
                          ),
                          subtitle: Text(
                            '${u.correo}\n${u.rol ?? ''} • ${u.estado ?? ''}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'editar') {
                                _editar(u);
                              } else if (v == 'desactivar') {
                                _desactivar(u);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                              if (u.activo)
                                const PopupMenuItem(
                                  value: 'desactivar',
                                  child: Text('Desactivar'),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
