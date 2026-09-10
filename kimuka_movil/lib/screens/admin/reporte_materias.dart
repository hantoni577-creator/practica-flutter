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
  String? _categoriaSeleccionada;
  bool _cargando = true;
  bool _exportando = false;

  List<dynamic> _materiales = [];
  List<Categoria> _categorias = [];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Map<String, String> _construirQuery() {
    final q = <String, String>{};
    if (_categoriaSeleccionada != null &&
        _categoriaSeleccionada!.isNotEmpty &&
        _categoriaSeleccionada != 'todos') {
      q['categoria'] = _categoriaSeleccionada!;
    }
    return q;
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    try {
      final api = context.read<ApiClient>();

      if (_categorias.isEmpty) {
        final resCat = await api.listarCategorias();
        _categorias = resCat
            .map((c) => Categoria.fromJson(c as Map<String, dynamic>))
            .toList();
      }

      final query = _construirQuery();
      final res = await api.request(
        '/api/reportes/materias-primas',
        query: query.isEmpty ? null : query,
      );

      if (!mounted) return;
      setState(() {
        if (res is Map<String, dynamic> && res['data'] is List) {
          _materiales = res['data'] as List<dynamic>;
        } else if (res is List) {
          _materiales = res;
        } else {
          _materiales = [];
        }
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _exportarExcel() async {
    setState(() => _exportando = true);
    try {
      final api = context.read<ApiClient>();
      final query = _construirQuery();

      final res = await api.download(
        '/api/reportes/materias-primas/excel',
        query: query.isEmpty ? null : query,
      );

      await exportarReporte(res, 'reporte_materias_primas', onError: _mostrar);
    } on ApiException catch (e) {
      _mostrar(e.message);
    } catch (e) {
      _mostrar('No se pudo exportar: $e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  void _mostrar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final totalMateriales = _materiales.length;
    double stockTotal = 0.0;
    int sinStock = 0;

    for (final elem in _materiales) {
      final m = elem as Map<String, dynamic>;
      final cant = (m['cantidad'] as num?)?.toDouble() ?? 0.0;
      stockTotal += cant;
      if (cant <= 0) {
        sinStock++;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(title: const Text('Reporte de Materias Primas')),
      body: _cargando
          ? const Cargando()
          : RefreshIndicator(
        onRefresh: _cargarTodo,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ENCABEZADO
                  const Text(
                    'Reporte de Materias Primas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Inventario general de materiales del sistema Kimuka.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.textoSecundario, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // TARJETAS MÉTRICAS
                  Row(
                    children: [
                      Expanded(
                        child: _tarjetaMetrica(
                          titulo: 'TOTAL MATERIALES',
                          valor: '$totalMateriales',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _tarjetaMetrica(
                          titulo: 'STOCK TOTAL',
                          valor: stockTotal.toStringAsFixed(2),
                          pie: 'Materiales sin stock: $sinStock',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // CARD DE FILTRO POR CATEGORÍA + BOTÓN EXPORTAR
                  Card(
                    color: AppTheme.bgCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, boxConstraints) {
                              final esPantallaAncha =
                                  boxConstraints.maxWidth > 700;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 14,
                                crossAxisAlignment:
                                WrapCrossAlignment.end,
                                alignment: WrapAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: esPantallaAncha ? 280 : 220,
                                    child: _selectorConEtiqueta(
                                      etiqueta: 'FILTRAR POR CATEGORÍA',
                                      child: DropdownButtonFormField<
                                          String?>(
                                        value: _categoriaSeleccionada,
                                        isExpanded: true,
                                        dropdownColor: AppTheme.bgCard,
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 13),
                                        decoration:
                                        _decoracionSelector(),
                                        items: [
                                          const DropdownMenuItem(
                                            value: null,
                                            child: Text(
                                                'Todas las categorías',
                                                overflow: TextOverflow
                                                    .ellipsis),
                                          ),
                                          ..._categorias.map(
                                                (c) => DropdownMenuItem(
                                              value: c.idCategoria,
                                              child: Text(
                                                  c.nombreCategoria,
                                                  overflow: TextOverflow
                                                      .ellipsis),
                                            ),
                                          ),
                                        ],
                                        onChanged: (v) {
                                          setState(() =>
                                          _categoriaSeleccionada = v);
                                          _cargarTodo();
                                        },
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(bottom: 2),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xFF107C41),
                                        foregroundColor: Colors.white,
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: _exportando
                                          ? null
                                          : _exportarExcel,
                                      icon: _exportando
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child:
                                        CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                          : const Icon(Icons.download,
                                          size: 18),
                                      label: const Text(
                                        'Exportar a Excel',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // GRÁFICA: INVENTARIO DE MATERIALES
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Inventario de Materiales',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 10,
                                      color: const Color(0xFF2ECC71),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Stock Disponible',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textoSecundario,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_materiales.isEmpty)
                            const Center(
                              child: Padding(
                                padding:
                                EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Sin materiales registrados',
                                  style: TextStyle(
                                      color: AppTheme.textoSecundario),
                                ),
                              ),
                            )
                          else
                            ..._materiales.map((elem) {
                              final m = elem as Map<String, dynamic>;
                              final nombre =
                                  m['nombreInsumo']?.toString() ?? '---';
                              final cant =
                                  (m['cantidad'] as num?)?.toDouble() ??
                                      0.0;
                              final unidad =
                                  m['nombreUnidad']?.toString() ?? '';

                              final maxStock = stockTotal > 0
                                  ? stockTotal
                                  : 1.0;
                              final ratio =
                              (cant / maxStock).clamp(0.05, 1.0);

                              return Padding(
                                padding:
                                const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          nombre,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${cant.toStringAsFixed(0)} $unidad'
                                              .trim(),
                                          style: const TextStyle(
                                            color: Color(0xFF2ECC71),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(6),
                                      child: Container(
                                        height: 14,
                                        width: double.infinity,
                                        color: AppTheme.bgInput,
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: ratio,
                                          child: Container(
                                            color:
                                            const Color(0xFF2ECC71),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TABLA: DETALLE DEL INVENTARIO
                  Card(
                    color: AppTheme.bgCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalle del Inventario',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_materiales.isEmpty)
                            const SinDatos(
                                mensaje:
                                'Sin inventario de materias primas')
                          else
                            _construirTabla(
                              columnas: const [
                                'Material',
                                'Categoría',
                                'Unidad',
                                'Stock',
                                'Estado'
                              ],
                              filas:
                              _materiales.map<List<dynamic>>((elem) {
                                final m = elem as Map<String, dynamic>;
                                final cant =
                                    (m['cantidad'] as num?)?.toDouble() ??
                                        0.0;
                                final cantTexto = cant % 1 == 0
                                    ? cant.toInt().toString()
                                    : cant.toStringAsFixed(2);
                                final estado =
                                cant > 0 ? 'Disponible' : 'Sin stock';

                                return [
                                  m['nombreInsumo']?.toString() ?? '---',
                                  m['nombreCategoria']?.toString() ??
                                      '---',
                                  m['nombreUnidad']?.toString() ?? '---',
                                  cantTexto,
                                  estado,
                                ];
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectorConEtiqueta(
      {required String etiqueta, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppTheme.textoSecundario,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _decoracionSelector() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: AppTheme.bgInput,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.acento),
      ),
    );
  }

  Widget _tarjetaMetrica(
      {required String titulo, required String valor, String? pie}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: AppTheme.textoSecundario,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          if (pie != null) ...[
            const SizedBox(height: 10),
            Text(
              pie,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirTabla(
      {required List<String> columnas, required List<List<dynamic>> filas}) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          children: columnas.map((c) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                c,
                style: const TextStyle(
                  color: AppTheme.textoSecundario,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
        ...filas.map((fila) {
          return TableRow(
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)),
            ),
            children: fila.asMap().entries.map((entry) {
              final colIndex = entry.key;
              final val = entry.value.toString();

              // Columna Estado (índice 4)
              if (colIndex == 4) {
                final esDisponible = val == 'Disponible';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: esDisponible
                            ? const Color(0xFF1B382B)
                            : const Color(0xFF381B1B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: esDisponible
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE53935),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        val,
                        style: TextStyle(
                          color: esDisponible
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  val,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}