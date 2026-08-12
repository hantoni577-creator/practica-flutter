import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../theme/app_theme.dart';
import '../../utils/exportar.dart';
import '../../widgets/common.dart';

class ReporteProduccionScreen extends StatefulWidget {
  const ReporteProduccionScreen({super.key});

  @override
  State<ReporteProduccionScreen> createState() =>
      _ReporteProduccionScreenState();
}

class _ReporteProduccionScreenState extends State<ReporteProduccionScreen> {
  late Future<List<dynamic>> _futuro;
  String? _mes;
  String? _anio;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<dynamic>> _cargar() async {
    final api = context.read<ApiClient>();
    return api.reporteProduccion(mes: _mes, anio: _anio);
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.exportarProduccion(mes: _mes, anio: _anio);
      await exportarReporte(res, 'reporte_produccion', onError: _mostrar);
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
        title: const Text('Reporte producción'),
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
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _mes,
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ..._meses().entries.map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          ),
                    ],
                    onChanged: (v) => setState(() {
                      _mes = v;
                      _futuro = _cargar();
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _anio,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      prefixIcon: Icon(Icons.event),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ..._anios().map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(a),
                            ),
                          ),
                    ],
                    onChanged: (v) => setState(() {
                      _anio = v;
                      _futuro = _cargar();
                    }),
                  ),
                ),
              ],
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
                            final detalles =
                                (d['detalles'] as List<dynamic>? ?? [])
                                    .map((x) => x as Map<String, dynamic>)
                                    .map((x) =>
                                        '${x['nombreProducto'] ?? '---'} x${x['cantidadTotal'] ?? 0}')
                                    .join('\n');
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: AppTheme.primario,
                                      foregroundColor: Colors.white,
                                      child: Icon(Icons.factory_outlined),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d['nombreCliente']?.toString() ??
                                                '---',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primario,
                                            ),
                                          ),
                                          Text(
                                            '${d['fechaPedido'] ?? ''}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppTheme.textoSecundario),
                                          ),
                                          if (detalles.isNotEmpty)
                                            Text(
                                              detalles,
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${d['unidades'] ?? 0} uds',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.acento,
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                              d['estadoProd']?.toString() ??
                                                  '---'),
                                          labelStyle: const TextStyle(
                                              fontSize: 11),
                                        ),
                                      ],
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
          ),
        ],
      ),
    );
  }

  Map<String, String> _meses() => {
        '01': 'Enero',
        '02': 'Febrero',
        '03': 'Marzo',
        '04': 'Abril',
        '05': 'Mayo',
        '06': 'Junio',
        '07': 'Julio',
        '08': 'Agosto',
        '09': 'Septiembre',
        '10': 'Octubre',
        '11': 'Noviembre',
        '12': 'Diciembre',
      };

  List<String> _anios() {
    final actual = DateTime.now().year;
    return [for (var a = actual; a >= actual - 4; a--) '$a'];
  }
}
