import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/asignacion.dart';
import '../../models/insumo.dart';
import '../../models/usuario.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class AsignarInsumosScreen extends StatefulWidget {
  const AsignarInsumosScreen({super.key});

  @override
  State<AsignarInsumosScreen> createState() => _AsignarInsumosScreenState();
}

class _AsignarInsumosScreenState extends State<AsignarInsumosScreen> {
  late Future<List<Asignacion>> _futuro;
  final _cantidad = TextEditingController();
  String? _idEmpleado;
  String? _idInsumo;
  bool _enviando = false;
  bool _abrirForm = false;
  List<Usuario> _empleados = [];
  List<Insumo> _insumos = [];

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
    _cargarOpciones();
  }

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  Future<List<Asignacion>> _cargar() async {
    final api = context.read<ApiClient>();
    final data = await api.listarAsignaciones();
    return data
        .map((a) => Asignacion.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<void> _cargarOpciones() async {
    try {
      final api = context.read<ApiClient>();
      final empleadosF = api.listarEmpleados();
      final insumosF = api.listarInsumos();
      final empleados = await empleadosF;
      final insumos = await insumosF;
      if (!mounted) return;
      setState(() {
        _empleados = empleados
            .map((u) => Usuario.fromJson(u as Map<String, dynamic>))
            .toList();
        _insumos = insumos
            .map((i) => Insumo.fromJson(i as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      // opciones opcionales
    }
  }

  Future<void> _asignar() async {
    final cantidad = double.tryParse(_cantidad.text.trim());
    if (_idEmpleado == null ||
        _idInsumo == null ||
        cantidad == null ||
        cantidad <= 0) {
      _mostrar('Completa todos los campos con valores válidos.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final api = context.read<ApiClient>();
      await api.crearAsignacion({
        'idUsuario_Empleado': _idEmpleado,
        'idInsumo': _idInsumo,
        'cantidad': cantidad,
      });
      if (!mounted) return;
      _mostrar('Insumo asignado correctamente.');
      setState(() {
        _abrirForm = false;
        _cantidad.clear();
        _idEmpleado = null;
        _idInsumo = null;
        _futuro = _cargar();
      });
      _cargarOpciones();
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
      appBar: AppBar(title: const Text('Asignar insumos')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.acento,
        foregroundColor: Colors.white,
        onPressed: () => setState(() => _abrirForm = !_abrirForm),
        child: Icon(_abrirForm ? Icons.close : Icons.add),
      ),
      body: Column(
        children: [
          if (_abrirForm)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TituloSeccion(texto: 'Nueva asignación'),
                    DropdownButtonFormField<String>(
                      initialValue: _idEmpleado,
                      decoration: const InputDecoration(
                        labelText: 'Empleado *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: _empleados
                          .map((u) => DropdownMenuItem(
                                value: u.idUsuario,
                                child: Text(u.nombre),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _idEmpleado = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _idInsumo,
                      decoration: const InputDecoration(
                        labelText: 'Insumo *',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      items: _insumos
                          .map((i) => DropdownMenuItem(
                                value: i.idInsumo,
                                child: Text(
                                  '${i.nombreInsumo} (${i.cantidad?.toStringAsFixed(1) ?? 'N/D'} ${i.nombreUnidad ?? ''})',
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _idInsumo = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cantidad,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad *',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _enviando ? null : _asignar,
                      child: _enviando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Asignar'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Asignacion>>(
              future: _futuro,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Cargando();
                }
                if (snapshot.hasError) {
                  return VistaError(
                    mensaje: snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : 'Error al cargar las asignaciones.',
                    onReintentar: () => setState(() => _futuro = _cargar()),
                  );
                }
                final asignaciones = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async =>
                      setState(() => _futuro = _cargar()),
                  child: asignaciones.isEmpty
                      ? ListView(children: const [SinDatos()])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: asignaciones.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final a = asignaciones[i];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppTheme.primario,
                                  foregroundColor: Colors.white,
                                  child: Icon(Icons.assignment_ind),
                                ),
                                title: Text(
                                  a.nombreEmpleado ?? '---',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '${a.nombreInsumo ?? '---'} • ${a.cantidad?.toStringAsFixed(0) ?? 'N/D'} • ${a.fechaAsignacion ?? ''}',
                                ),
                                trailing: Chip(
                                  label: Text(a.estado ?? '---'),
                                  backgroundColor: a.completada
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFDE9C8),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: a.completada
                                        ? AppTheme.exito
                                        : AppTheme.acento,
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
}
