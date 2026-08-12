import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/categoria.dart';
import '../../theme/app_theme.dart';
import '../../utils/exportar.dart';
import '../../widgets/common.dart';

class ReporteMateriasScreen extends StatefulWidget {
  const ReporteMateriasScreen({super.key});

  @override
  State<ReporteMateriasScreen> createState() => _ReporteMateriasScreenState();
}

class _ReporteMateriasScreenState extends State<ReporteMateriasScreen> {
  late Future<List<dynamic>> _futuro;
  String? _categoria;
  bool _exportando = false;
  List<Categoria> _categorias = [];

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
    _cargarCategorias();
  }

  Future<List<dynamic>> _cargar() async {
    final api = context.read<ApiClient>();
    return api.reporteMateriasPrimas(categoria: _categoria);
  }

  Future<void> _cargarCategorias() async {
    try {
      final api = context.read<ApiClient>();
      final data = await api.listarCategorias();
      if (!mounted) return;
      setState(() {
        _categorias = data
            .map((c) => Categoria.fromJson(c as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      // opcional
    }
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.exportarMateriasPrimas(categoria: _categoria);
      await exportarReporte(res, 'reporte_materias_primas',
          onError: _mostrar);
    } on ApiException catch (e) {
      _mostrar(e.message);
    } catch (_) {
      _mostrar('No se pudo exportar el reporte.');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  void _mostrar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte materias primas'),
        actions: [
          IconButton(
            tooltip: 'Exportar a Excel',
            onPressed: _exportando ? null : _exportar,
            icon: _exportando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todas'),
                ),
                ..._categorias.map(
                  (c) => DropdownMenuItem(
                    value: c.idCategoria,
                    child: Text(c.nombreCategoria),
                  ),
                ),
              ],
              onChanged: (v) => setState(() {
                _categoria = v;
                _futuro = _cargar();
              }),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _futuro,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Cargando();
                }
                if (snapshot.hasError) {
                  return VistaError(
                    mensaje: snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : 'Error al cargar el reporte.',
                    onReintentar: () => setState(() => _futuro = _cargar()),
                  );
                }
                final datos = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async =>
                      setState(() => _futuro = _cargar()),
                  child: datos.isEmpty
                      ? ListView(children: const [SinDatos()])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: datos.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final d = datos[i] as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppTheme.acento,
                                  foregroundColor: Colors.white,
                                  child: Icon(Icons.inventory_2_outlined),
                                ),
                                title: Text(
                                  d['nombreInsumo']?.toString() ?? '---',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primario,
                                  ),
                                ),
                                subtitle: Text(
                                  '${d['nombreCategoria'] ?? ''} • ${d['nombreUnidad'] ?? ''}',
                                ),
                                trailing: Text(
                                  '${d['cantidad'] ?? '0'} ${d['nombreUnidad'] ?? ''}'.trim(),
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
          ),
        ],
      ),
    );
  }
}
