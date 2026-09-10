import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/asignacion.dart';
import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  late Future<List<Asignacion>> _futuro;
  bool _cambiando = false;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Asignacion>> _cargar() async {
    final api = context.read<ApiClient>();
    final user = context.read<AuthProvider>().user;
    if (user == null) throw ApiException('Sesión no válida');
    final data = await api.asignacionesPorEmpleado(user.idUsuario);
    return data
        .map((a) => Asignacion.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<void> _marcarCompletada(Asignacion asignacion) async {
    setState(() => _cambiando = true);
    try {
      final api = context.read<ApiClient>();
      await api.cambiarEstadoAsignacion(
          asignacion.idAsignacion, {'estado': 'Completada'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea completada correctamente.')),
      );
      setState(() => _futuro = _cargar());
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo conectar con el servidor')),
        );
      }
    } finally {
      if (mounted) setState(() => _cambiando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain, // Fondo oscuro
      appBar: AppBar(
        title: const Text('Isumos Asignados Para Trabajar '),
        centerTitle: false,
      ),
      body: FutureBuilder<List<Asignacion>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Cargando();
          }
          if (snapshot.hasError) {
            return VistaError(
              mensaje: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Error al cargar tus tareas.',
              onReintentar: () => setState(() => _futuro = _cargar()),
            );
          }
          final tareas = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _futuro = _cargar()),
            child: tareas.isEmpty
                ? ListView(
              children: const [
                SinDatos(mensaje: 'No tienes tareas asignadas.')
              ],
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tareas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final tarea = tareas[i];
                final completada = tarea.completada;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: completada
                          ? AppTheme.exito.withValues(alpha: 0.2)
                          : AppTheme.bgInput,
                      foregroundColor: completada
                          ? AppTheme.exito
                          : AppTheme.acento,
                      child: Icon(completada
                          ? Icons.check_circle
                          : Icons.pending_actions),
                    ),
                    title: Text(
                      tarea.nombreInsumo ?? '---',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary, // Blanco nítido
                      ),
                    ),
                    subtitle: Text(
                      'Cantidad: ${tarea.cantidad?.toStringAsFixed(0) ?? 'N/D'} • ${tarea.fechaAsignacion ?? ''}',
                      style: const TextStyle(color: AppTheme.textoSecundario),
                    ),
                    trailing: completada
                        ? Chip(
                      label: const Text('Completada'),
                      backgroundColor: AppTheme.exito.withValues(alpha: 0.2),
                      side: const BorderSide(color: AppTheme.exito),
                      labelStyle: const TextStyle(
                        color: AppTheme.exito,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : TextButton(
                      onPressed: _cambiando
                          ? null
                          : () => _marcarCompletada(tarea),
                      child: const Text(
                        'Completar',
                        style: TextStyle(
                          color: AppTheme.acento,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
