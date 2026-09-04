import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/asignacion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class TareasAdminScreen extends StatefulWidget {
  const TareasAdminScreen({super.key});

  @override
  State<TareasAdminScreen> createState() => _TareasAdminScreenState();
}

class _TareasAdminScreenState extends State<TareasAdminScreen> {
  late Future<List<Asignacion>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Asignacion>> _cargar() async {
    final api = context.read<ApiClient>();
    final data = await api.listarAsignaciones();
    return data
        .map((a) => Asignacion.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<void> _cambiarEstado(Asignacion a, String estado) async {
    try {
      final api = context.read<ApiClient>();
      await api.cambiarEstadoAsignacion(a.idAsignacion, {'estado': estado});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a $estado.')),
      );
      setState(() => _futuro = _cargar());
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas de empleados')),
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
                  : 'Error al cargar las tareas.',
              onReintentar: () => setState(() => _futuro = _cargar()),
            );
          }
          final tareas = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _futuro = _cargar()),
            child: tareas.isEmpty
                ? ListView(children: const [SinDatos()])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: tareas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final t = tareas[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppTheme.primario,
                                foregroundColor: Colors.white,
                                child: Icon(Icons.assignment),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.nombreEmpleado ?? '---',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${t.nombreInsumo ?? '---'} • ${t.cantidad?.toStringAsFixed(0) ?? 'N/D'} • ${t.fechaAsignacion ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textoSecundario),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownButton<String>(
                                value: t.estado,
                                underline: const SizedBox.shrink(),
                                items: ['Pendiente', 'En Proceso', 'Completada']
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null && v != t.estado) {
                                    _cambiarEstado(t, v);
                                  }
                                },
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
