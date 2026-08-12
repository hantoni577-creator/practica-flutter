import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/jornada.dart';
import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../widgets/common.dart';

class MisHorasScreen extends StatefulWidget {
  const MisHorasScreen({super.key});

  @override
  State<MisHorasScreen> createState() => _MisHorasScreenState();
}

class _MisHorasScreenState extends State<MisHorasScreen> {
  late Future<({List<Jornada> jornadas, Map<String, dynamic> calculo})>
      _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<({List<Jornada> jornadas, Map<String, dynamic> calculo})>
      _cargar() async {
    final api = context.read<ApiClient>();
    final user = context.read<AuthProvider>().user;
    if (user == null) throw ApiException('Sesión no válida');
    final res = await api.jornadasPorEmpleado(user.idUsuario);
    final calculo = await api.calcularPagoJornada(user.idUsuario);
    final jornadas = ((res['jornadas'] as List<dynamic>?) ?? const [])
        .map((j) => Jornada.fromJson(j as Map<String, dynamic>))
        .toList();
    return (jornadas: jornadas, calculo: calculo);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Cargando();
        }
        if (snapshot.hasError) {
          return VistaError(
            mensaje: snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Error al cargar tus horas.',
            onReintentar: () => setState(() => _futuro = _cargar()),
          );
        }
        final data = snapshot.data!;
        final horas = (data.calculo['horasTotales'] as num?)?.toDouble() ?? 0;
        final tarifa =
            (data.calculo['tarifaPorHora'] as num?)?.toDouble() ?? 0;
        final pago = (data.calculo['pagoTotal'] as num?)?.toDouble() ?? 0;
        final total = (data.calculo['totalJornadas'] as num?)?.toInt() ?? 0;
        return RefreshIndicator(
          onRefresh: () async => setState(() => _futuro = _cargar()),
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
                                color: AppTheme.primario),
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
              if (data.jornadas.isEmpty)
                const SinDatos(mensaje: 'Aún no has registrado jornadas.')
              else
                ...data.jornadas.map(
                  (j) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: j.activa
                            ? AppTheme.exito
                            : AppTheme.primario,
                        foregroundColor: Colors.white,
                        child: Icon(j.activa
                            ? Icons.play_circle
                            : Icons.check_circle),
                      ),
                      title: Text(
                        j.fecha ?? '---',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primario,
                        ),
                      ),
                      subtitle: Text(
                        'Entrada ${formatearHora(j.hInicio)}  •  Salida ${formatearHora(j.hFin)}',
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
              color: AppTheme.primario,
            ),
          ),
        ],
      ),
    );
  }
}
