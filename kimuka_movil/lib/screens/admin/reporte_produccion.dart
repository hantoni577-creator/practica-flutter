import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/cliente.dart';
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
  String? _filtroCliente;
  String? _filtroMes;
  String? _filtroAnio;
  String? _filtroEstado;

  bool _cargando = true;
  bool _exportando = false;

  List<dynamic> _ordenes = [];
  List<dynamic> _productosRanking = [];
  List<Cliente> _clientes = [];

  static const _estados = ['En proceso', 'Entregado', 'Cancelado'];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Map<String, String> _construirQuery() {
    final q = <String, String>{};
    if (_filtroCliente != null && _filtroCliente!.isNotEmpty) {
      q['cliente'] = _filtroCliente!;
    }
    if (_filtroMes != null && _filtroMes!.isNotEmpty) {
      q['mes'] = _filtroMes!;
    }
    if (_filtroAnio != null && _filtroAnio!.isNotEmpty) {
      q['anio'] = _filtroAnio!;
    }
    if (_filtroEstado != null && _filtroEstado!.isNotEmpty) {
      q['estado'] = _filtroEstado!;
    }
    return q;
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    try {
      final api = context.read<ApiClient>();

      if (_clientes.isEmpty) {
        final resClientes = await api.listarClientes();
        _clientes = resClientes
            .map((c) => Cliente.fromJson(c as Map<String, dynamic>))
            .toList();
      }

      final query = _construirQuery();
      final res = await api.request(
        '/api/reportes/produccion',
        query: query.isEmpty ? null : query,
      );

      if (!mounted) return;
      setState(() {
        if (res is Map<String, dynamic>) {
          _ordenes = (res['data'] as List<dynamic>?) ?? [];
          _productosRanking = (res['productos'] as List<dynamic>?) ?? [];
        } else if (res is List) {
          _ordenes = res;
          _productosRanking = [];
        } else {
          _ordenes = [];
          _productosRanking = [];
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
        '/api/reportes/produccion/excel',
        query: query.isEmpty ? null : query,
      );

      await exportarReporte(res, 'reporte_produccion', onError: _mostrar);
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

  String _nombreEstado(String? est) {
    final e = est?.toString().trim().toLowerCase() ?? '';
    if (e == '✔' || e == 'entregado') return 'Entregado';
    if (e == '✖' || e == 'cancelado') return 'Cancelado';
    return 'En Proceso';
  }

  Color _colorEstado(String estadoNombre) {
    switch (estadoNombre) {
      case 'Entregado':
        return const Color(0xFF4CAF50);
      case 'Cancelado':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFFFB74D);
    }
  }

  Color _bgEstado(String estadoNombre) {
    switch (estadoNombre) {
      case 'Entregado':
        return const Color(0xFF1B382B);
      case 'Cancelado':
        return const Color(0xFF381B1B);
      default:
        return const Color(0xFF382D1B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalOrdenes = _ordenes.length;
    int totalUnidades = 0;
    int entregadas = 0;
    int enProceso = 0;
    int canceladas = 0;
    final Set<String> clientesUnicos = {};

    // Conteo de órdenes por mes para el segundo gráfico
    final Map<String, int> ordenesPorMes = {};

    for (final item in _ordenes) {
      final o = item as Map<String, dynamic>;
      final u = (o['unidades'] as num?)?.toInt() ?? 0;
      totalUnidades += u;

      final est = _nombreEstado(o['estadoProd']?.toString());
      if (est == 'Entregado') entregadas++;
      if (est == 'Cancelado') canceladas++;
      if (est == 'En Proceso') enProceso++;

      final cliente = o['nombreCliente']?.toString();
      if (cliente != null && cliente.isNotEmpty && cliente != '---') {
        clientesUnicos.add(cliente);
      }

      final fecha = o['fechaPedido']?.toString() ?? '';
      if (fecha.length >= 7) {
        final mesNum = fecha.substring(5, 7);
        final nombreMes = _meses()[mesNum] ?? mesNum;
        ordenesPorMes[nombreMes] = (ordenesPorMes[nombreMes] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(title: const Text('Reporte de Producción')),
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
                    'Reporte de Producción',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Órdenes de producción y unidades fabricadas del sistema Kimuka.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.textoSecundario, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // BARRA DE FILTROS + BOTÓN EXPORTAR VERDE
                  Card(
                    color: AppTheme.bgCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, boxConstraints) {
                          final esPantallaAncha =
                              boxConstraints.maxWidth > 850;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 14,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              // Filtro Cliente
                              SizedBox(
                                width: esPantallaAncha ? 180 : 150,
                                child: _selectorConEtiqueta(
                                  etiqueta: 'CLIENTE',
                                  child: DropdownButtonFormField<String?>(
                                    value: _filtroCliente,
                                    isExpanded: true,
                                    dropdownColor: AppTheme.bgCard,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13),
                                    decoration: _decoracionSelector(),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Todos los clientes',
                                            overflow:
                                            TextOverflow.ellipsis),
                                      ),
                                      ..._clientes.map(
                                            (c) => DropdownMenuItem(
                                          value: c.nombreCliente,
                                          child: Text(c.nombreCliente,
                                              overflow:
                                              TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _filtroCliente = v);
                                      _cargarTodo();
                                    },
                                  ),
                                ),
                              ),
                              // Filtro Mes
                              SizedBox(
                                width: esPantallaAncha ? 130 : 120,
                                child: _selectorConEtiqueta(
                                  etiqueta: 'MES',
                                  child: DropdownButtonFormField<String?>(
                                    value: _filtroMes,
                                    isExpanded: true,
                                    dropdownColor: AppTheme.bgCard,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13),
                                    decoration: _decoracionSelector(),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Todos los meses',
                                            overflow:
                                            TextOverflow.ellipsis),
                                      ),
                                      ..._meses().entries.map(
                                            (e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value,
                                              overflow:
                                              TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _filtroMes = v);
                                      _cargarTodo();
                                    },
                                  ),
                                ),
                              ),
                              // Filtro Año
                              SizedBox(
                                width: esPantallaAncha ? 120 : 110,
                                child: _selectorConEtiqueta(
                                  etiqueta: 'AÑO',
                                  child: DropdownButtonFormField<String?>(
                                    value: _filtroAnio,
                                    isExpanded: true,
                                    dropdownColor: AppTheme.bgCard,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13),
                                    decoration: _decoracionSelector(),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Todos los años',
                                            overflow:
                                            TextOverflow.ellipsis),
                                      ),
                                      ..._anios().map(
                                            (a) => DropdownMenuItem(
                                          value: a,
                                          child: Text(a,
                                              overflow:
                                              TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _filtroAnio = v);
                                      _cargarTodo();
                                    },
                                  ),
                                ),
                              ),
                              // Filtro Estado
                              SizedBox(
                                width: esPantallaAncha ? 140 : 130,
                                child: _selectorConEtiqueta(
                                  etiqueta: 'ESTADO',
                                  child: DropdownButtonFormField<String?>(
                                    value: _filtroEstado,
                                    isExpanded: true,
                                    dropdownColor: AppTheme.bgCard,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13),
                                    decoration: _decoracionSelector(),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Todos los estados',
                                            overflow:
                                            TextOverflow.ellipsis),
                                      ),
                                      ..._estados.map(
                                            (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s,
                                              overflow:
                                              TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _filtroEstado = v);
                                      _cargarTodo();
                                    },
                                  ),
                                ),
                              ),
                              // Botón verde Exportar a Excel
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF107C41),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed:
                                  _exportando ? null : _exportarExcel,
                                  icon: _exportando
                                      ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
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
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TARJETAS MÉTRICAS
                  Row(
                    children: [
                      Expanded(
                        child: _tarjetaMetrica(
                          titulo: 'TOTAL UNIDADES',
                          valor: '$totalUnidades',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _tarjetaMetrica(
                          titulo: 'TOTAL ÓRDENES',
                          valor: '$totalOrdenes',
                          pie:
                          'Entregadas: $entregadas · En proceso: $enProceso · Canceladas: $canceladas\nClientes: ${clientesUnicos.length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // GRÁFICA 1: UNIDADES FABRICADAS POR PRODUCTO
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
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Unidades Fabricadas por Producto',
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
                                      color: const Color(0xFFFFA000),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Unidades Fabricadas',
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
                          if (_productosRanking.isEmpty)
                            const Center(
                              child: Padding(
                                padding:
                                EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Sin registros para graficar',
                                  style: TextStyle(
                                      color: AppTheme.textoSecundario),
                                ),
                              ),
                            )
                          else
                            ..._productosRanking.map((prod) {
                              final p = prod as Map<String, dynamic>;
                              final nombre =
                                  p['nombre']?.toString() ?? '---';
                              final unidades =
                                  (p['unidades'] as num?)?.toInt() ?? 0;
                              final maxU = totalUnidades > 0
                                  ? totalUnidades.toDouble()
                                  : 1.0;
                              final ratio =
                              (unidades / maxU).clamp(0.05, 1.0);

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
                                          '$unidades',
                                          style: const TextStyle(
                                            color: Color(0xFFFFA000),
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
                                            color: const Color(0xFFFFA000),
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

                  // GRÁFICA 2: ÓRDENES DE PRODUCCIÓN POR MES
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
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Órdenes de Producción por Mes',
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
                                      'N° de Órdenes',
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
                          if (ordenesPorMes.isEmpty)
                            const Center(
                              child: Padding(
                                padding:
                                EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Sin registros para graficar',
                                  style: TextStyle(
                                      color: AppTheme.textoSecundario),
                                ),
                              ),
                            )
                          else
                            ...ordenesPorMes.entries.map((entry) {
                              final maxO = totalOrdenes > 0
                                  ? totalOrdenes.toDouble()
                                  : 1.0;
                              final ratio =
                              (entry.value / maxO).clamp(0.05, 1.0);

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
                                          entry.key,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${entry.value}',
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
                                            color: const Color(0xFF2ECC71),
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

                  // TABLA: DETALLE DE ÓRDENES DE PRODUCCIÓN
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
                            'Detalle de Órdenes de Producción',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_ordenes.isEmpty)
                            const SinDatos(
                                mensaje:
                                'Sin órdenes de producción registradas')
                          else
                            _construirTabla(
                              columnas: const [
                                'ID Orden',
                                'Cliente',
                                'Fecha Pedido',
                                'Estado',
                                'Productos',
                                'Unidades'
                              ],
                              filas: _ordenes.map<List<dynamic>>((elem) {
                                final o = elem as Map<String, dynamic>;
                                final detalles =
                                    (o['detalles'] as List<dynamic>?) ??
                                        [];
                                final numProductos = detalles.length;
                                final unidades =
                                    (o['unidades'] as num?)?.toInt() ?? 0;
                                final estadoTexto = _nombreEstado(
                                    o['estadoProd']?.toString());

                                return [
                                  o['idOrden']?.toString() ?? '---',
                                  o['nombreCliente']?.toString() ?? '---',
                                  o['fechaPedido']?.toString() ?? '---',
                                  estadoTexto,
                                  '$numProductos',
                                  '$unidades',
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

              // Columna Estado (índice 3)
              if (colIndex == 3) {
                final colorBorde = _colorEstado(val);
                final colorFondo = _bgEstado(val);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorFondo,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorBorde, width: 0.8),
                      ),
                      child: Text(
                        val,
                        style: TextStyle(
                          color: colorBorde,
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
