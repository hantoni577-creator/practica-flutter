import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/metodo_pago.dart';
import '../../models/pago.dart';
import '../../models/usuario.dart';
import '../../state/auth_provider.dart';
import '../../state/pagos_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class AprobarPagoScreen extends StatefulWidget {
  const AprobarPagoScreen({super.key});

  @override
  State<AprobarPagoScreen> createState() => _AprobarPagoScreenState();
}

class _AprobarPagoScreenState extends State<AprobarPagoScreen> {
  final _montoCtrl = TextEditingController();

  String? _idEmpleadoSeleccionado;
  String? _idJornadaSeleccionada;
  String? _idMetodo;

  double _horasJornada = 0.0;
  double _pagoEstimado = 0.0;

  bool _cargandoInicial = true;
  bool _cargandoJornadas = false;
  bool _enviando = false;

  List<Usuario> _empleados = [];
  List<dynamic> _jornadasPendientes = [];
  List<MetodoPago> _metodos = [];
  List<Pago> _historialPagos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _cargandoInicial = true);
    try {
      final api = context.read<ApiClient>();

      final resEmpleados = await api.request('/api/empleados');
      final resMetodos = await api.listarMetodosPago();
      final resPagos = await api.listarPagos();

      if (!mounted) return;

      final listaEmp = (resEmpleados is List) ? resEmpleados : (resEmpleados['data'] as List? ?? []);
      _empleados = listaEmp.map((e) => Usuario.fromJson(e as Map<String, dynamic>)).toList();

      _metodos = resMetodos.map((m) => MetodoPago.fromJson(m as Map<String, dynamic>)).toList();
      _historialPagos = resPagos.map((p) => Pago.fromJson(p as Map<String, dynamic>)).toList();

      if (_metodos.isNotEmpty) {
        _idMetodo = _metodos.first.idMetodo;
      }
    } catch (_) {
      if (mounted) _mostrar('Error al cargar datos del servidor');
    } finally {
      if (mounted) setState(() => _cargandoInicial = false);
    }
  }

  Future<void> _alSeleccionarEmpleado(String? idEmpleado) async {
    if (idEmpleado == null) return;
    setState(() {
      _idEmpleadoSeleccionado = idEmpleado;
      _idJornadaSeleccionada = null;
      _horasJornada = 0.0;
      _pagoEstimado = 0.0;
      _montoCtrl.clear();
      _cargandoJornadas = true;
    });

    try {
      final api = context.read<ApiClient>();
      final res = await api.request('/api/jornadas/pendientes/$idEmpleado');
      final lista = (res is List) ? res : (res['data'] as List? ?? []);

      if (!mounted) return;
      setState(() {
        _jornadasPendientes = lista;
      });
    } catch (_) {
      if (mounted) _mostrar('No se pudieron obtener las jornadas pendientes');
    } finally {
      if (mounted) setState(() => _cargandoJornadas = false);
    }
  }

  void _alSeleccionarJornada(String? idJornada) {
    if (idJornada == null) return;
    final j = _jornadasPendientes.firstWhere(
          (elem) => elem['idJornada'] == idJornada,
      orElse: () => null,
    );

    if (j != null) {
      setState(() {
        _idJornadaSeleccionada = idJornada;
        _horasJornada = (j['horas'] as num?)?.toDouble() ?? 0.0;
        _pagoEstimado = (j['pagoEstimado'] as num?)?.toDouble() ?? 0.0;
        _montoCtrl.text = _pagoEstimado.toStringAsFixed(0);
      });
    }
  }

  Future<void> _registrarPago() async {
    final monto = double.tryParse(_montoCtrl.text.trim());
    if (_idEmpleadoSeleccionado == null ||
        _idJornadaSeleccionada == null ||
        _idMetodo == null ||
        monto == null ||
        monto <= 0) {
      _mostrar('Completa todos los campos con valores válidos.');
      return;
    }

    setState(() => _enviando = true);
    try {
      final user = context.read<AuthProvider>().user;

      final exito = await context.read<PagosProvider>().crearPago({
        'idJornada': _idJornadaSeleccionada,
        'idUsuario_Admin': user?.idUsuario,
        'montoPagado': monto,
        'idMetodo': _idMetodo,
        'fechaPago': DateTime.now().toIso8601String().split('T').first,
      });

      if (!mounted) return;

      if (exito) {
        _mostrar('Pago registrado correctamente.');
        // Refrescar jornadas pendientes e historial
        await _alSeleccionarEmpleado(_idEmpleadoSeleccionado);
        final api = context.read<ApiClient>();
        final resPagos = await api.listarPagos();
        if (mounted) {
          setState(() {
            _historialPagos =
                resPagos.map((p) => Pago.fromJson(p as Map<String, dynamic>)).toList();
          });
        }
      } else {
        final errorMsg = context.read<PagosProvider>().error;
        _mostrar(errorMsg ?? 'No se pudo aprobar el pago.');
      }
    } on ApiException catch (e) {
      _mostrar(e.message);
    } catch (_) {
      _mostrar('No se pudo conectar con el servidor.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(title: const Text('Registrar Pago')),
      body: _cargandoInicial
          ? const Cargando()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final esPantallaAncha = constraints.maxWidth > 700;
                return Flex(
                  direction: esPantallaAncha ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FORMULARIO PRINCIPAL
                    Expanded(
                      flex: esPantallaAncha ? 3 : 0,
                      child: Card(
                        color: AppTheme.bgCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'EMPLEADO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textoSecundario,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _idEmpleadoSeleccionado,
                                dropdownColor: AppTheme.bgCard,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'Seleccione un empleado',
                                  prefixIcon: Icon(Icons.person_outline,
                                      color: AppTheme.textoSecundario),
                                ),
                                items: _empleados
                                    .map((e) => DropdownMenuItem(
                                  value: e.idUsuario,
                                  child: Text(e.nombre),
                                ))
                                    .toList(),
                                onChanged: _alSeleccionarEmpleado,
                              ),
                              const SizedBox(height: 16),

                              // Tarjeta de Horas y Pago Estimado
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgInput,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Horas jornada: ',
                                            style: TextStyle(
                                                color: AppTheme.textoSecundario,
                                                fontSize: 14)),
                                        Text(
                                          '${_horasJornada.toStringAsFixed(2)} hrs',
                                          style: const TextStyle(
                                              color: AppTheme.acento,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Text('Pago estimado: ',
                                            style: TextStyle(
                                                color: AppTheme.textoSecundario,
                                                fontSize: 14)),
                                        Text(
                                          '\$ ${_pagoEstimado.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              color: AppTheme.acento,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'JORNADA A PAGAR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textoSecundario,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _cargandoJornadas
                                  ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                                  : DropdownButtonFormField<String>(
                                value: _idJornadaSeleccionada,
                                dropdownColor: AppTheme.bgCard,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'Seleccione una jornada',
                                  prefixIcon: Icon(Icons.schedule,
                                      color: AppTheme.textoSecundario),
                                ),
                                items: _jornadasPendientes.map((j) {
                                  return DropdownMenuItem<String>(
                                    value: j['idJornada'].toString(),
                                    child: Text(
                                      '${j['fecha']} (${j['hInicio']} - ${j['hFin']})',
                                    ),
                                  );
                                }).toList(),
                                onChanged: _alSeleccionarJornada,
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'MONTO A PAGAR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textoSecundario,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _montoCtrl,
                                keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: AppTheme.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  prefixIcon: Icon(Icons.payments_outlined,
                                      color: AppTheme.textoSecundario),
                                ),
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'MÉTODO DE PAGO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textoSecundario,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _idMetodo,
                                dropdownColor: AppTheme.bgCard,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                                      color: AppTheme.textoSecundario),
                                ),
                                items: _metodos
                                    .map((m) => DropdownMenuItem(
                                  value: m.idMetodo,
                                  child: Text(m.nombreMetodo),
                                ))
                                    .toList(),
                                onChanged: (v) => setState(() => _idMetodo = v),
                              ),
                              const SizedBox(height: 24),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.textPrimary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: _enviando ? null : _registrarPago,
                                child: _enviando
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                                    : const Text(
                                  'Registrar Pago',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (esPantallaAncha) const SizedBox(width: 20) else const SizedBox(height: 20),

                    // HISTORIAL LATERAL DE PAGOS
                    Expanded(
                      flex: esPantallaAncha ? 2 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Historial de Pagos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_historialPagos.isEmpty)
                            const SinDatos(mensaje: 'Sin pagos registrados')
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 500),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: _historialPagos.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final p = _historialPagos[i];
                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgCard,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          p.idPago,
                                          style: const TextStyle(
                                            color: AppTheme.textoSecundario,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '\$ ${p.montoPagado?.toStringAsFixed(0) ?? '0'}',
                                          style: const TextStyle(
                                            color: AppTheme.exito,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${p.nombreMetodo ?? 'Efectivo'} | ${p.fechaPago ?? ''}',
                                          style: const TextStyle(
                                            color: AppTheme.textoSecundario,
                                            fontSize: 12,
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
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
