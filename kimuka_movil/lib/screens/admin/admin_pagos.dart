import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pago.dart';
import '../../state/pagos_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../widgets/common.dart';

class AdminPagosScreen extends StatefulWidget {
  const AdminPagosScreen({super.key});

  @override
  State<AdminPagosScreen> createState() => _AdminPagosScreenState();
}

class _AdminPagosScreenState extends State<AdminPagosScreen> {
  @override
  void initState() {
    super.initState();
    // Carga los datos al entrar si aún no están en memoria
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PagosProvider>().fetchPagos();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escucha activamente los cambios del Provider
    final pagosProv = context.watch<PagosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pagos')),
      body: Builder(
        builder: (context) {
          if (pagosProv.isLoading && pagosProv.pagos.isEmpty) {
            return const Cargando();
          }

          if (pagosProv.error != null && pagosProv.pagos.isEmpty) {
            return VistaError(
              mensaje: pagosProv.error!,
              onReintentar: () => pagosProv.fetchPagos(),
            );
          }

          final pagos = pagosProv.pagos;
          double total = 0;
          for (final p in pagos) {
            total += p.montoPagado ?? 0;
          }

          return RefreshIndicator(
            onRefresh: () => pagosProv.fetchPagos(),
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
                            color: AppTheme.textPrimary,
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
                            color: AppTheme.textPrimary,
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
