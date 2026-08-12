import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/pago.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../widgets/common.dart';

class AdminPagosScreen extends StatefulWidget {
  const AdminPagosScreen({super.key});

  @override
  State<AdminPagosScreen> createState() => _AdminPagosScreenState();
}

class _AdminPagosScreenState extends State<AdminPagosScreen> {
  late Future<List<Pago>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Pago>> _cargar() async {
    final api = context.read<ApiClient>();
    final data = await api.listarPagos();
    return data
        .map((p) => Pago.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos')),
      body: FutureBuilder<List<Pago>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Cargando();
          }
          if (snapshot.hasError) {
            return VistaError(
              mensaje: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Error al cargar los pagos.',
              onReintentar: () => setState(() => _futuro = _cargar()),
            );
          }
          final pagos = snapshot.data!;
          double total = 0;
          for (final p in pagos) {
            total += p.montoPagado ?? 0;
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _futuro = _cargar()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total pagado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primario,
                          ),
                        ),
                        Text(
                          formatearMoneda(total),
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
                if (pagos.isEmpty)
                  const SinDatos()
                else
                  ...pagos.map(
                    (p) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primario,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.payments),
                        ),
                        title: Text(
                          formatearMoneda(p.montoPagado),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primario,
                          ),
                        ),
                        subtitle: Text(
                          '${p.fechaPago ?? ''}\n${p.nombreMetodo ?? ''} • Jornada ${p.idJornada ?? '---'}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
