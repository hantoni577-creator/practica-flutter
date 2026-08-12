import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../theme/app_theme.dart';
import '../../utils/exportar.dart';
import '../../utils/formato.dart';
import '../../widgets/common.dart';

class ReporteHorasScreen extends StatefulWidget {
  const ReporteHorasScreen({super.key});

  @override
  State<ReporteHorasScreen> createState() => _ReporteHorasScreenState();
}

class _ReporteHorasScreenState extends State<ReporteHorasScreen> {
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
    return api.reporteHoras(mes: _mes, anio: _anio);
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.exportarHoras(mes: _mes, anio: _anio);
      await exportarReporte(res, 'reporte_horas',
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
        title: const Text('Reporte horas'),
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
                double totalHoras = 0;
                for (final d in datos) {
                  totalHoras +=
                      ((d as Map<String, dynamic>)['horas'] as num?)?.toDouble() ??
                          0;
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      setState(() => _futuro = _cargar()),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total horas registradas',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primario),
                              ),
                              Text(
                                '${totalHoras.toStringAsFixed(1)} h',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.acento,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (datos.isEmpty)
                        const SinDatos()
                      else
                        ...datos.map(
                          (d) => Card(
                            child: ListTile(
                              title: Text(
                                (d as Map<String, dynamic>)['nombreEmpleado']
                                        ?.toString() ??
                                    '---',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primario,
                                ),
                              ),
                              subtitle: Text(
                                '${d['fecha'] ?? ''}\n${formatearHora(d['hInicio']?.toString())} → ${formatearHora(d['hFin']?.toString())}',
                              ),
                              isThreeLine: true,
                              trailing: Text(
                                '${d['horas'] ?? '0'} h',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.acento,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
