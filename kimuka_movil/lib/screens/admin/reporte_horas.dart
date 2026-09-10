import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/usuario.dart';
import '../../theme/app_theme.dart';
import '../../utils/exportar.dart';
import '../../widgets/common.dart';

class ReporteHorasScreen extends StatefulWidget {
  const ReporteHorasScreen({super.key});

  @override
  State<ReporteHorasScreen> createState() => _ReporteHorasScreenState();
}

class _ReporteHorasScreenState extends State<ReporteHorasScreen> {
  String? _filtroEmpleado;
  String? _filtroMes;
  String? _filtroAnio;

  bool _cargando = true;
  bool _exportando = false;

  List<dynamic> _jornadas = [];
  List<Usuario> _empleados = [];

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
        '/api/reportes/horas',
        query: query.isEmpty ? null : query,
      );

      if (!mounted) return;
      setState(() {
        if (res is Map<String, dynamic> && res['data'] is List) {
          _jornadas = res['data'] as List<dynamic>;
        } else if (res is List) {
          _jornadas = res;
        } else {
          _jornadas = [];
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
        '/api/reportes/horas/excel',
        query: query.isEmpty ? null : query,
      );

      await exportarReporte(res, 'reporte_horas', onError: _mostrar);
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
    // Cálculos estadísticos
    final totalJornadas = _jornadas.length;
    double totalHoras = 0.0;
    int enCurso = 0;

    // Agrupación de horas por empleado para la barra comparativa
    final Map<String, double> horasPorEmpleado = {};

    for (final item in _jornadas) {
      final j = item as Map<String, dynamic>;
      final h = (j['horas'] as num?)?.toDouble() ?? 0.0;
      totalHoras += h;

      if (j['hFin'] == null || j['hFin'].toString().trim().isEmpty) {
        enCurso++;
      }

      final nombreEmp = j['nombreEmpleado']?.toString() ?? 'Desconocido';
      horasPorEmpleado[nombreEmp] = (horasPorEmpleado[nombreEmp] ?? 0.0) + h;
    }

    final promedio = totalJornadas > 0 ? (totalHoras / totalJornadas) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(title: const Text('Reporte de Horas Trabajadas')),
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
                    'Reporte de Horas Trabajadas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jornadas laborales y horas trabajadas por los empleados del sistema Kimuka.',
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
                                width: esPantallaAncha ? 220 : 180,
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
                                width: esPantallaAncha ? 150 : 130,
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
                                width: esPantallaAncha ? 140 : 120,
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

                  // TARJETAS MÉTRICAS (TOTAL HORAS & TOTAL JORNADAS)
                  Row(
                    children: [
                      Expanded(
                        child: _tarjetaMetrica(
                          titulo: 'TOTAL HORAS',
                          valor: '${totalHoras.toStringAsFixed(2)} hrs',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _tarjetaMetrica(
                          titulo: 'TOTAL JORNADAS',
                          valor: '$totalJornadas',
                          pie:
                          'Promedio por jornada: ${promedio.toStringAsFixed(2)} hrs\nJornadas en curso: $enCurso',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // GRÁFICA / BARRAS: HORAS POR EMPLEADO
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
                                  'Horas por Empleado',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 10,
                                      color: const Color(0xFFFFA000),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Horas Trabajadas',
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
                          if (horasPorEmpleado.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Sin registros para graficar',
                                  style: TextStyle(color: AppTheme.textoSecundario),
                                ),
                              ),
                            )
                          else
                            ...horasPorEmpleado.entries.map((entry) {
                              final double maxH = totalHoras > 0 ? totalHoras : 1.0;
                              final double ratio = (entry.value / maxH).clamp(0.05, 1.0);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          '${entry.value.toStringAsFixed(2)} hrs',
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
                                      borderRadius: BorderRadius.circular(6),
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

                  // TABLA: DETALLE DE JORNADAS
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
                            'Detalle de Jornadas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_jornadas.isEmpty)
                            const SinDatos(mensaje: 'Sin jornadas registradas')
                          else
                            _construirTabla(
                              columnas: const [
                                'Empleado',
                                'Fecha',
                                'Entrada',
                                'Salida',
                                'Horas',
                                'Estado'
                              ],
                              filas: _jornadas.map<List<dynamic>>((elem) {
                                final j = elem as Map<String, dynamic>;
                                final entrada = (j['hInicio']?.toString() ?? '')
                                    .split('.')
                                    .first;
                                final salidaRaw = j['hFin']?.toString();
                                final salida = (salidaRaw != null &&
                                    salidaRaw.trim().isNotEmpty)
                                    ? salidaRaw.split('.').first
                                    : '---';

                                final horasVal =
                                    (j['horas'] as num?)?.toDouble() ?? 0.0;
                                final horasTexto = horasVal > 0
                                    ? '${horasVal.toStringAsFixed(2)} hrs'
                                    : '---';

                                final esCompletada =
                                    salida != '---' && salida.isNotEmpty;

                                return [
                                  j['nombreEmpleado']?.toString() ?? '---',
                                  j['fecha']?.toString() ?? '---',
                                  entrada.length > 5 ? entrada.substring(0, 5) : entrada,
                                  salida.length > 5 ? salida.substring(0, 5) : salida,
                                  horasTexto,
                                  esCompletada ? 'Completada' : 'En curso',
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
              style: const TextStyle(fontSize: 11, color: AppTheme.textoSecundario),
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

              // La última columna es el estado (Completada / En curso)
              if (colIndex == fila.length - 1) {
                final esCompletada = val == 'Completada';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: esCompletada
                            ? const Color(0xFF1B382B)
                            : const Color(0xFF382D1B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: esCompletada
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFFFA000),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        val,
                        style: TextStyle(
                          color: esCompletada
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFB74D),
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