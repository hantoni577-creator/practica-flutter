import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/jornada.dart';
import '../../state/auth_provider.dart';
import '../../state/horas_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../widgets/common.dart';

class MisHorasScreen extends StatefulWidget {
  const MisHorasScreen({super.key});

  @override
  State<MisHorasScreen> createState() => _MisHorasScreenState();
}

class _MisHorasScreenState extends State<MisHorasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<HorasProvider>().fetchMisHoras(user.idUsuario);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final horasProv = context.watch<HorasProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgMain, // Fondo oscuro total
      body: Builder(
        builder: (context) {
          if (horasProv.isLoading && horasProv.jornadas.isEmpty) {
            return const Cargando();
          }

          if (horasProv.error != null && horasProv.jornadas.isEmpty) {
            return VistaError(
              mensaje: horasProv.error!,
              onReintentar: () {
                final user = context.read<AuthProvider>().user;
                if (user != null) {
                  horasProv.fetchMisHoras(user.idUsuario);
                }
              },
            );
          }

          final calculo = horasProv.calculo;
          final jornadas = horasProv.jornadas;

          final horas = (calculo['horasTotales'] as num?)?.toDouble() ?? 0;
          final tarifa = (calculo['tarifaPorHora'] as num?)?.toDouble() ?? 0;
          final pago = (calculo['pagoTotal'] as num?)?.toDouble() ?? 0;
          final total = (calculo['totalJornadas'] as num?)?.toInt() ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              final user = context.read<AuthProvider>().user;
              if (user != null) {
                await horasProv.fetchMisHoras(user.idUsuario);
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const TituloSeccion(texto: 'Resumen'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _fila('Horas totales', '${horas.toStringAsFixed(1)} h'),
                        _fila('Jornadas registradas', '$total'),
                        _fila('Tarifa por hora', formatearMoneda(tarifa)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pago proyectado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              formatearMoneda(pago),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.acento,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const TituloSeccion(texto: 'Historial de jornadas'),
                if (jornadas.isEmpty)
                  const SinDatos(mensaje: 'Aún no has registrado jornadas.')
                else
                  ...jornadas.map(
                        (j) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: j.activa
                              ? AppTheme.exito
                              : AppTheme.bgInput,
                          foregroundColor: Colors.white,
                          child: Icon(
                            j.activa ? Icons.play_circle : Icons.check_circle,
                            color: j.activa ? Colors.black : Colors.white,
                          ),
                        ),
                        title: Text(
                          j.fecha ?? '---',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Entrada ${formatearHora(j.hInicio)}  •  Salida ${formatearHora(j.hFin)}',
                          style: const TextStyle(color: AppTheme.textoSecundario),
                        ),
                        trailing: Text(
                          calcularDuracion(j.hInicio, j.hFin),
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
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: const TextStyle(color: AppTheme.textoSecundario)),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
