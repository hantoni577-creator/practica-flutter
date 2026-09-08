import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _buscadorCtrl = TextEditingController();
  List<Insumo> _todosLosInsumos = [];
  List<Insumo> _insumosFiltrados = [];
  List<Categoria> _categorias = [];
  String? _categoriaSeleccionada; // null = Todas las categorías
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _buscadorCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final insumosData = await api.listarInsumos();
      final categoriasData = await api.listarCategorias();

      if (!mounted) return;

      _todosLosInsumos = insumosData
          .map((i) => Insumo.fromJson(i as Map<String, dynamic>))
          .toList();

      _categorias = categoriasData
          .map((c) => Categoria.fromJson(c as Map<String, dynamic>))
          .toList();

      _aplicarFiltros();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Error al cargar los insumos');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _aplicarFiltros() {
    final query = _buscadorCtrl.text.trim().toLowerCase();

    setState(() {
      _insumosFiltrados = _todosLosInsumos.where((insumo) {
        final coincideNombre = insumo.nombreInsumo.toLowerCase().contains(query);
        final coincideCategoria = _categoriaSeleccionada == null ||
            insumo.idCategoria == _categoriaSeleccionada;
        return coincideNombre && coincideCategoria;
      }).toList();
    });
  }

  Future<void> _abrirFormulario({Insumo? insumo}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioInsumoScreen(insumo: insumo),
      ),
    );
    if (mounted) _cargarDatos();
  }

  Future<void> _eliminar(Insumo insumo) async {
    final api = context.read<ApiClient>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Eliminar insumo', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '¿Deseas eliminar "${insumo.nombreInsumo}" del inventario?',
          style: const TextStyle(color: AppTheme.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textoSecundario)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.peligro,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 36),
            ),
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
        const SnackBar(content: Text('Insumo eliminado del inventario.')),
      );
      _cargarDatos();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: const Text('Materia Prima'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.acento,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Añadir Insumo', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _abrirFormulario(),
      ),
      body: _cargando
          ? const Cargando()
          : _error != null
          ? VistaError(mensaje: _error!, onReintentar: _cargarDatos)
          : RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Barra de búsqueda y selector de categorías
            Card(
              color: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BUSCAR POR NOMBRE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _buscadorCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      onChanged: (_) => _aplicarFiltros(),
                      decoration: InputDecoration(
                        hintText: 'Escriba el nombre...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textoSecundario),
                        suffixIcon: _buscadorCtrl.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textoSecundario),
                          onPressed: () {
                            _buscadorCtrl.clear();
                            _aplicarFiltros();
                          },
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CATEGORÍA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _categoriaSeleccionada,
                      dropdownColor: AppTheme.bgCard,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined, color: AppTheme.textoSecundario),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las categorías'),
                        ),
                        ..._categorias.map(
                              (cat) => DropdownMenuItem<String?>(
                            value: cat.idCategoria,
                            child: Text(cat.nombreCategoria),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        _categoriaSeleccionada = val;
                        _aplicarFiltros();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de Insumos
            if (_insumosFiltrados.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: SinDatos(mensaje: 'No se encontraron insumos con esos filtros.'),
              )
            else
              ..._insumosFiltrados.map((insumo) {
                final cantidadStr = insumo.cantidad?.toStringAsFixed(1) ?? '0.0';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: AppTheme.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.bgInput,
                      child: const Icon(Icons.inventory_2_outlined, color: AppTheme.acento),
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
                      style: const TextStyle(color: AppTheme.textoSecundario),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$cantidadStr ${insumo.nombreUnidad ?? ''}'.trim(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.acento,
                          ),
                        ),
                        PopupMenuButton<String>(
                          iconColor: AppTheme.textoSecundario,
                          color: AppTheme.bgCard,
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
                              child: Text('Editar', style: TextStyle(color: AppTheme.textPrimary)),
                            ),
                            PopupMenuItem(
                              value: 'eliminar',
                              child: Text('Eliminar', style: TextStyle(color: AppTheme.peligro)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
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
    _cantidad.text = i?.cantidad != null ? i!.cantidad.toString() : '';
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
    final nombre = _nombre.text.trim();
    final cantidadStr = _cantidad.text.trim();

    if (nombre.isEmpty || _idCategoria == null || _idUnidad == null || cantidadStr.isEmpty) {
      _mostrar('Completa todos los campos obligatorios (*).');
      return;
    }

    final cantidad = double.tryParse(cantidadStr);

    // Validación estricta: bloquea números negativos o cero
    if (cantidad == null || cantidad <= 0) {
      _mostrar('La cantidad debe ser un número mayor a 0.');
      return;
    }

    setState(() => _enviando = true);
    try {
      final api = context.read<ApiClient>();
      final payload = {
        'nombreInsumo': nombre,
        'idCategoria': _idCategoria,
        'idUnidad': _idUnidad,
        'cantidad': cantidad,
      };

      if (widget.insumo == null) {
        await api.crearInsumo(payload);
        _mostrar('Insumo registrado correctamente.');
      } else {
        await api.actualizarInsumo(widget.insumo!.idInsumo, payload);
        _mostrar('Insumo actualizado correctamente.');
      }

      if (!mounted) return;
      Navigator.of(context).pop();
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
    final esNuevo = widget.insumo == null;

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: Text(esNuevo ? 'Registrar Ingreso de Materia Prima' : 'Editar Insumo'),
      ),
      body: _cargandoOpciones
          ? const Cargando()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              color: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'NOMBRE DEL MATERIAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nombre,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Ej: Tela Algodón',
                        prefixIcon: Icon(Icons.inventory_2_outlined, color: AppTheme.textoSecundario),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CATEGORÍA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _idCategoria,
                      dropdownColor: AppTheme.bgCard,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined, color: AppTheme.textoSecundario),
                      ),
                      items: _categorias
                          .map((c) => DropdownMenuItem(
                        value: c.idCategoria,
                        child: Text(c.nombreCategoria),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _idCategoria = v),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'UNIDAD DE MEDIDA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _idUnidad,
                      dropdownColor: AppTheme.bgCard,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.straighten, color: AppTheme.textoSecundario),
                      ),
                      items: _unidades
                          .map((u) => DropdownMenuItem(
                        value: u.idUnidad,
                        child: Text(u.nombreUnidad),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _idUnidad = v),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CANTIDAD INICIAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cantidad,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Permite únicamente números positivos y un punto decimal
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0',
                        prefixIcon: Icon(Icons.numbers, color: AppTheme.textoSecundario),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textoSecundario,
                              side: const BorderSide(color: AppTheme.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.textPrimary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            onPressed: _enviando ? null : _guardar,
                            child: _enviando
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                                : Text(
                              esNuevo ? 'Registrar en Inventario' : 'Guardar Cambios',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
