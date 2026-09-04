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
        backgroundColor: AppTheme.bgCard,
        title: const Text('Desactivar usuario', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
            '¿Desactivar a ${usuario.nombre}? No podrá iniciar sesión.',
            style: const TextStyle(color: AppTheme.textoSecundario)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textoSecundario)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.peligro,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 36),
            ),
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

  Future<void> _activar(Usuario usuario) async {
    final api = context.read<ApiClient>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Reactivar usuario', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
            '¿Deseas reactivar a ${usuario.nombre}? Podrá volver a iniciar sesión.',
            style: const TextStyle(color: AppTheme.textoSecundario)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textoSecundario)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.exito,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 36),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await api.activarUsuario(usuario.idUsuario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario reactivado con éxito.')),
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
      backgroundColor: AppTheme.bgMain,
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
                          ? AppTheme.bgInput
                          : AppTheme.peligro.withValues(alpha: 0.2),
                      foregroundColor: u.activo
                          ? AppTheme.textPrimary
                          : AppTheme.peligro,
                      child: Icon(u.activo ? Icons.person : Icons.person_off),
                    ),
                    title: Text(
                      u.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: u.activo
                            ? AppTheme.textPrimary
                            : AppTheme.textoSecundario,
                        decoration: u.activo
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.correo,
                          style: const TextStyle(color: AppTheme.textoSecundario),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              u.rol ?? '',
                              style: const TextStyle(color: AppTheme.textoSecundario, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: u.activo
                                    ? AppTheme.exito.withValues(alpha: 0.15)
                                    : AppTheme.peligro.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: u.activo ? AppTheme.exito : AppTheme.peligro,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                u.activo ? 'ACTIVO' : 'INACTIVO',
                                style: TextStyle(
                                  color: u.activo ? AppTheme.exito : AppTheme.peligro,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      color: AppTheme.bgCard,
                      iconColor: AppTheme.textSecondary,
                      onSelected: (v) {
                        if (v == 'editar') {
                          _editar(u);
                        } else if (v == 'desactivar') {
                          _desactivar(u);
                        } else if (v == 'activar') {
                          _activar(u);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Text('Editar', style: TextStyle(color: AppTheme.textPrimary)),
                        ),
                        if (u.activo)
                          const PopupMenuItem(
                            value: 'desactivar',
                            child: Text('Desactivar', style: TextStyle(color: AppTheme.peligro)),
                          )
                        else
                          const PopupMenuItem(
                            value: 'activar',
                            child: Text('Activar', style: TextStyle(color: AppTheme.exito)),
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
