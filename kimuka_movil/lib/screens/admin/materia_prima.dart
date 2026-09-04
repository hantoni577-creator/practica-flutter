import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/categoria.dart';
import '../../models/insumo.dart';
import '../../models/unidad_medida.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class MateriaPrimaScreen extends StatefulWidget {
  const MateriaPrimaScreen({super.key});

  @override
  State<MateriaPrimaScreen> createState() => _MateriaPrimaScreenState();
}

class _MateriaPrimaScreenState extends State<MateriaPrimaScreen> {
  late Future<List<Insumo>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Insumo>> _cargar() async {
    final api = context.read<ApiClient>();
    final data = await api.listarInsumos();
    return data
        .map((i) => Insumo.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<void> _abrirFormulario({Insumo? insumo}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioInsumoScreen(insumo: insumo),
      ),
    );
    if (mounted) setState(() => _futuro = _cargar());
  }

  Future<void> _eliminar(Insumo insumo) async {
    final api = context.read<ApiClient>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar insumo'),
        content: Text('¿Eliminar ${insumo.nombreInsumo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.eliminarInsumo(insumo.idInsumo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insumo eliminado.')),
      );
      setState(() => _futuro = _cargar());
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materia prima')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.acento,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Insumo>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Cargando();
          }
          if (snapshot.hasError) {
            return VistaError(
              mensaje: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Error al cargar los insumos.',
              onReintentar: () => setState(() => _futuro = _cargar()),
            );
          }
          final insumos = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _futuro = _cargar()),
            child: insumos.isEmpty
                ? ListView(children: const [SinDatos()])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: insumos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final insumo = insumos[i];
                      final cantidad =
                          insumo.cantidad?.toStringAsFixed(1) ?? 'N/D';
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primario,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.inventory_2_outlined),
                          ),
                          title: Text(
                            insumo.nombreInsumo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            [insumo.nombreCategoria, insumo.nombreUnidad]
                                .whereType<String>()
                                .join(' • '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cantidad,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.acento,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'editar') {
                                    _abrirFormulario(insumo: insumo);
                                  } else if (v == 'eliminar') {
                                    _eliminar(insumo);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'eliminar',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class FormularioInsumoScreen extends StatefulWidget {
  const FormularioInsumoScreen({super.key, this.insumo});

  final Insumo? insumo;

  @override
  State<FormularioInsumoScreen> createState() => _FormularioInsumoScreenState();
}

class _FormularioInsumoScreenState extends State<FormularioInsumoScreen> {
  final _nombre = TextEditingController();
  final _cantidad = TextEditingController();
  String? _idCategoria;
  String? _idUnidad;
  List<Categoria> _categorias = [];
  List<UnidadMedida> _unidades = [];
  bool _enviando = false;
  bool _cargandoOpciones = true;

  @override
  void initState() {
    super.initState();
    final i = widget.insumo;
    _nombre.text = i?.nombreInsumo ?? '';
    _cantidad.text = i?.cantidad?.toString() ?? '';
    _idCategoria = i?.idCategoria;
    _idUnidad = i?.idUnidad;
    _cargarOpciones();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _cantidad.dispose();
    super.dispose();
  }

  Future<void> _cargarOpciones() async {
    try {
      final api = context.read<ApiClient>();
      final categoriasF = api.listarCategorias();
      final unidadesF = api.listarUnidadesMedida();
      final categorias = await categoriasF;
      final unidades = await unidadesF;
      if (!mounted) return;
      setState(() {
        _categorias = categorias
            .map((c) => Categoria.fromJson(c as Map<String, dynamic>))
            .toList();
        _unidades = unidades
            .map((u) => UnidadMedida.fromJson(u as Map<String, dynamic>))
            .toList();
        _cargandoOpciones = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoOpciones = false);
    }
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty ||
        _cantidad.text.trim().isEmpty ||
        _idCategoria == null ||
        _idUnidad == null) {
      _mostrar('Completa todos los campos.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final api = context.read<ApiClient>();
      final payload = {
        'nombreInsumo': _nombre.text.trim(),
        'idCategoria': _idCategoria,
        'idUnidad': _idUnidad,
        'cantidad': double.tryParse(_cantidad.text.trim()) ?? 0,
      };
      if (widget.insumo == null) {
        await api.crearInsumo(payload);
        _mostrar('Insumo creado correctamente.');
      } else {
        await api.actualizarInsumo(widget.insumo!.idInsumo, payload);
        _mostrar('Insumo actualizado correctamente.');
      }
      if (!mounted) return;
      Navigator.of(context).pop();
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
    final esNuevo = widget.insumo == null;
    return Scaffold(
      appBar: AppBar(title: Text(esNuevo ? 'Nuevo insumo' : 'Editar insumo')),
      body: _cargandoOpciones
          ? const Cargando()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del insumo *',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _idCategoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _categorias
                        .map((c) => DropdownMenuItem(
                              value: c.idCategoria,
                              child: Text(c.nombreCategoria),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _idCategoria = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _idUnidad,
                    decoration: const InputDecoration(
                      labelText: 'Unidad de medida *',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    items: _unidades
                        .map((u) => DropdownMenuItem(
                              value: u.idUnidad,
                              child: Text(u.nombreUnidad),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _idUnidad = v),
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _enviando ? null : _guardar,
                    child: _enviando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ),
    );
  }
}
