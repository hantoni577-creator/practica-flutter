import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/insumo.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  late Future<List<Insumo>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Insumo>> _cargar() async {
    final api = context.read<ApiClient>();
    final data = await api.listarInsumos();
    return data
        .map((i) => Insumo.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain, // Fondo oscuro
      appBar: AppBar(
        title: const Text('Materia Prima Disponible'),
        centerTitle: false,
      ),
      body: FutureBuilder<List<Insumo>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Cargando();
          }
          if (snapshot.hasError) {
            return VistaError(
              mensaje: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Error al cargar el inventario.',
              onReintentar: () => setState(() => _futuro = _cargar()),
            );
          }
          final insumos = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _futuro = _cargar()),
            child: insumos.isEmpty
                ? ListView(children: const [SinDatos()])
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: insumos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final insumo = insumos[i];
                final cantidad =
                    insumo.cantidad?.toStringAsFixed(1) ?? 'N/D';
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.bgInput,
                      foregroundColor: AppTheme.acento,
                      child: Icon(Icons.inventory_2_outlined),
                    ),
                    title: Text(
                      insumo.nombreInsumo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary, // Blanco nítido
                      ),
                    ),
                    subtitle: Text(
                      [insumo.nombreCategoria, insumo.nombreUnidad]
                          .whereType<String>()
                          .join(' • '),
                      style: const TextStyle(color: AppTheme.textoSecundario),
                    ),
                    trailing: Text(
                      '$cantidad ${insumo.nombreUnidad ?? ''}'.trim(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.acento,
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
