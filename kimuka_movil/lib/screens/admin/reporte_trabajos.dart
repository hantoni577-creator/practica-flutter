import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/usuario.dart';
import '../../theme/app_theme.dart';
import '../../utils/exportar.dart';
import '../../widgets/common.dart';

class ReporteTrabajosScreen extends StatefulWidget {
  const ReporteTrabajosScreen({super.key});

  @override
  State<ReporteTrabajosScreen> createState() => _ReporteTrabajosScreenState();
}

class _ReporteTrabajosScreenState extends State<ReporteTrabajosScreen> {
  String? _filtroEmpleado;
  String? _filtroMes;
  String? _filtroAnio;
  String? _filtroEstado;

  bool _cargando = true;
  bool _exportando = false;

  Map<String, dynamic> _datos = {};
  List<Usuario> _empleados = [];

  static const _estados = ['En proceso', 'Completada', 'Pendiente'];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Map<String, String> _construirQuery() {
    final q = <String, String>{};
    if (_filtroEmpleado != null && _filtroEmpleado!.isNotEmpty) {
      q['empleado'] = _filtroEmpleado!;
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

      if (_empleados.isEmpty) {
        final resEmp = await api.listarEmpleados();
        _empleados = resEmp
            .map((e) => Usuario.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final query = _construirQuery();
      final res = await api.request(
        '/api/reportes/trabajos',
        query: query.isEmpty ? null : query,
      );

      if (!mounted) return;
      setState(() {
        if (res is Map<String, dynamic>) {
          _datos = (res['data'] is Map<String, dynamic>)
              ? res['data'] as Map<String, dynamic>
              : res;
        } else {
          _datos = {};
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
        '/api/reportes/trabajos/excel',
        query: query.isEmpty ? null : query,
      );

      await exportarReporte(res, 'reporte_trabajos', onError: _mostrar);
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
    final int total = (_datos['total'] as num?)?.toInt() ?? 0;
    final int completadas = (_datos['completadas'] as num?)?.toInt() ?? 0;
    final int enProceso = (_datos['enProceso'] as num?)?.toInt() ?? 0;
    final int pendientes = (_datos['pendientes'] as num?)?.toInt() ?? 0;
    final List<dynamic> rankingMateriales =
        (_datos['rankingMateriales'] as List<dynamic>?) ?? [];
    final List<dynamic> rankingEmpleados =
        (_datos['rankingEmpleados'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(title: const Text('Trabajos Más Realizados')),
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
                  const Text(
                    'Trabajos Más Realizados',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Materiales más asignados y empleados más activos del sistema Kimuka.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textoSecundario, fontSize: 13),
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
                          final esPantallaAncha = boxConstraints.maxWidth > 850;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 14,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              // Filtro Empleado
                              SizedBox(
                                width: esPantallaAncha ? 200 : 170,
                                child: _selectorConEtiqueta(
                                  etiqueta: 'EMPLEADO',
                                  child: DropdownButtonFormField<String?>(
                                    value: _filtroEmpleado,
                                    isExpanded: true,
                                    dropdownColor: AppTheme.bgCard,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary, fontSize: 13),
                                    decoration: _decoracionSelector(),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Todos los empleados',
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      ..._empleados.map(
                                            (e) => DropdownMenuItem(
                                          value: e.idUsuario,
                                          child: Text(e.nombre,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _filtroEmpleado = v);
                                      _cargarTodo();
                                    },
                                  ),
                                ),
                              ),
                              // Filtro Mes
                              SizedBox(
                                width: esPantallaAncha ? 140 : 130,
                                child: _selectorConEtiqueta(
                                  etiqueta: 'MES',
                                  child: DropdownButtonFormField<String?>(
                                    value: _filtroMes,
                                    isExpanded: true,
                                    dropdownColor: AppTheme.bgCard,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary, fontSize: 13),
                                    decoration: _decoracionSelector(),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Todos los meses',
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      ..._meses().entries.map(
                                            (e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value,
                                              overflow: TextOverflow.ellipsis),
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
                                width: esPantallaAncha ? 130 : 120,
                                child: _selectorConEtiqueta(
                                  etiqueta: 'AÑO',
                                  child: DropdownButtonFormField<String?>(
                                    value: _filtroAnio,
                                    isExpanded: true,
                                    dropdownColor: AppTheme.bgCard,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary, fontSize: 13),
                                    decoration: _decoracionSelector(),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Todos los años',
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      ..._anios().map(
                                            (a) => DropdownMenuItem(
                                          value: a,
                                          child: Text(a,
                                              overflow: TextOverflow.ellipsis),
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
                                width: esPantallaAncha ? 160 : 140,
                                child: _selectorConEtiqueta(
                                  etiqueta: 'ESTADO',
                                  child: DropdownButtonFormField<String?>(
                                    value: _filtroEstado,
                                    isExpanded: true,
                                    dropdownColor: AppTheme.bgCard,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary, fontSize: 13),
                                    decoration: _decoracionSelector(),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Todos los estados',
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      ..._estados.map(
                                            (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s,
                                              overflow: TextOverflow.ellipsis),
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
                                    backgroundColor: const Color(0xFF107C41),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _exportando ? null : _exportarExcel,
                                  icon: _exportando
                                      ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Icon(Icons.download, size: 18),
                                  label: const Text(
                                    'Exportar a Excel',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13),
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
                          titulo: 'TOTAL ASIGNACIONES',
                          valor: '$total',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _tarjetaMetrica(
                          titulo: 'COMPLETADAS',
                          valor: '$completadas',
                          pie: 'En proceso: $enProceso   |   Pendientes: $pendientes',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // TABLA: RANKING DE MATERIALES
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
                            'Ranking de Materiales Más Asignados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (rankingMateriales.isEmpty)
                            const SinDatos(mensaje: 'Sin registros de materiales')
                          else
                            _construirTabla(
                              columnas: const [
                                '#',
                                'Material',
                                'Asignaciones',
                                'Cantidad Total'
                              ],
                              filas: rankingMateriales
                                  .asMap()
                                  .entries
                                  .map<List<String>>((entry) {
                                final i = entry.key + 1;
                                final m = entry.value as Map<String, dynamic>;
                                return [
                                  '$i',
                                  m['nombre']?.toString() ?? '---',
                                  '${m['count'] ?? 0}',
                                  (m['cantidad'] as num?)?.toStringAsFixed(2) ?? '0.00',
                                ];
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TABLA: RANKING DE EMPLEADOS
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
                            'Ranking de Empleados Más Activos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (rankingEmpleados.isEmpty)
                            const SinDatos(mensaje: 'Sin registros de empleados')
                          else
                            _construirTabla(
                              columnas: const [
                                '#',
                                'Empleado',
                                'Total Trabajos',
                                'Completados'
                              ],
                              filas: rankingEmpleados
                                  .asMap()
                                  .entries
                                  .map<List<String>>((entry) {
                                final i = entry.key + 1;
                                final e = entry.value as Map<String, dynamic>;
                                return [
                                  '$i',
                                  e['nombre']?.toString() ?? '---',
                                  '${e['count'] ?? 0}',
                                  '${e['completadas'] ?? 0}',
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

  Widget _selectorConEtiqueta({required String etiqueta, required Widget child}) {
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

  Widget _tarjetaMetrica({required String titulo, required String valor, String? pie}) {
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
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          if (pie != null) ...[
            const SizedBox(height: 10),
            Text(
              pie,
              style: const TextStyle(fontSize: 11, color: AppTheme.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirTabla(
      {required List<String> columnas, required List<List<String>> filas}) {
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
            children: fila.map((texto) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  texto,
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