import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/jornada.dart';
import '../../models/metodo_pago.dart';
import '../../state/auth_provider.dart';
import '../../state/pagos_provider.dart';
import '../../widgets/common.dart';

class AprobarPagoScreen extends StatefulWidget {
  const AprobarPagoScreen({super.key});

  @override
  State<AprobarPagoScreen> createState() => _AprobarPagoScreenState();
}

class _AprobarPagoScreenState extends State<AprobarPagoScreen> {
  final _monto = TextEditingController();
  String? _idJornada;
  String? _idMetodo;
  bool _enviando = false;
  bool _cargando = true;
  List<MetodoPago> _metodos = [];
  List<Jornada> _jornadas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final api = context.read<ApiClient>();
      final metodosF = api.listarMetodosPago();
      final jornadasF = api.listarJornadas();
      final metodos = await metodosF;
      final jornadas = await jornadasF;
      if (!mounted) return;
      setState(() {
        _metodos = metodos
            .map((m) => MetodoPago.fromJson(m as Map<String, dynamic>))
            .toList();
        _jornadas = jornadas
            .map((j) => Jornada.fromJson(j as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudieron cargar las opciones de pago.')),
      );
    }
  }

  Future<void> _aprobar() async {
    final monto = double.tryParse(_monto.text.trim());
    if (_idJornada == null || _idMetodo == null || monto == null || monto <= 0) {
      _mostrar('Completa todos los campos con valores válidos.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final user = context.read<AuthProvider>().user;

      final exito = await context.read<PagosProvider>().crearPago({
        'idJornada': _idJornada,
        'idUsuario_Admin': user?.idUsuario,
        'montoPagado': monto,
        'idMetodo': _idMetodo,
        'fechaPago': DateTime.now().toIso8601String().split('T').first,
      });

      if (!mounted) return;

      if (exito) {
        _mostrar('Pago aprobado correctamente.');
        Navigator.of(context).pop(); // Al regresar a AdminPagosScreen, la lista ya se habrá actualizado
      } else {
        final errorMsg = context.read<PagosProvider>().error;
        _mostrar(errorMsg ?? 'No se pudo aprobar el pago.');
      }
    } on ApiException catch (e) {
      _mostrar(e.message);
    } catch (_) {
      _mostrar('No se pudo conectar con el servidor');
    } finally {
      if (mounted) setState(() => _enviando = false);
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
      appBar: AppBar(title: const Text('Aprobar pago')),
      body: _cargando
          ? const Cargando()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _idJornada,
              decoration: const InputDecoration(
                labelText: 'Jornada asociada *',
                prefixIcon: Icon(Icons.schedule),
              ),
              items: _jornadas
                  .map((j) => DropdownMenuItem(
                value: j.idJornada,
                child: Text(
                    '${j.nombreEmpleado ?? '---'} • ${j.fecha ?? ''}'),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _idJornada = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _idMetodo,
              decoration: const InputDecoration(
                labelText: 'Método de pago *',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              items: _metodos
                  .map((m) => DropdownMenuItem(
                value: m.idMetodo,
                child: Text(m.nombreMetodo),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _idMetodo = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _monto,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto a pagar *',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _enviando ? null : _aprobar,
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirmar aprobación'),
            ),
          ],
        ),
      ),
    );
  }
}
