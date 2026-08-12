import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/jornada.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../widgets/common.dart';

class AdminHorasScreen extends StatefulWidget {
  const AdminHorasScreen({super.key});

  @override
  State<AdminHorasScreen> createState() => _AdminHorasScreenState();
}

class _AdminHorasScreenState extends State<AdminHorasScreen> {
  late Future<List<Jornada>> _futuro;
  String? _mes;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Jornada>> _cargar() async {
    final api = context.read<ApiClient>();
    var data = await api.listarJornadas();
    if (_mes != null) {
      data = data
          .where((j) {
            final jj = Jornada.fromJson(j as Map<String, dynamic>);
            return (jj.mes ?? '') == _mes;
          })
          .toList();
    }
    return data
        .map((j) => Jornada.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horas de empleados')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DropdownButtonFormField<String>(
              initialValue: _mes,
              decoration: const InputDecoration(
                labelText: 'Filtrar por mes',
                prefixIcon: Icon(Icons.filter_alt_outlined),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos los meses'),
                ),
                ..._meses().entries.map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    ),
              ],
              onChanged: (v) {
                setState(() {
                  _mes = v;
                  _futuro = _cargar();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Jornada>>(
              future: _futuro,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Cargando();
                }
                if (snapshot.hasError) {
                  return VistaError(
                    mensaje: snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : 'Error al cargar las jornadas.',
                    onReintentar: () => setState(() => _futuro = _cargar()),
                  );
                }
                final jornadas = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async =>
                      setState(() => _futuro = _cargar()),
                  child: jornadas.isEmpty
                      ? ListView(children: const [SinDatos()])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: jornadas.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final j = jornadas[i];
                            return Card(
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
                                  j.nombreEmpleado ?? '---',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primario,
                                  ),
                                ),
                                subtitle: Text(
                                  '${j.fecha ?? ''}\nEntrada ${formatearHora(j.hInicio)} • Salida ${formatearHora(j.hFin)}',
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  calcularDuracion(j.hInicio, j.hFin),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.acento,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
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
}
