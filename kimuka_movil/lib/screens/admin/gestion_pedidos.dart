import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/cliente.dart';
import '../../models/orden.dart';
import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class GestionPedidosScreen extends StatefulWidget {
  const GestionPedidosScreen({super.key});

  @override
  State<GestionPedidosScreen> createState() => _GestionPedidosScreenState();
}

class _GestionPedidosScreenState extends State<GestionPedidosScreen> {
  late Future<List<Orden>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Orden>> _cargar() async {
    final api = context.read<ApiClient>();
    final data = await api.listarOrdenes();
    return data
        .map((o) => Orden.fromJson(o as Map<String, dynamic>))
        .toList();
  }

  Future<void> _abrirFormulario({Orden? orden}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioPedidoScreen(orden: orden),
      ),
    );
    if (mounted) setState(() => _futuro = _cargar());
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'Entregado':
        return AppTheme.exito;
      case 'Cancelado':
        return AppTheme.peligro;
      default:
        return AppTheme.acento;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de pedidos')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.acento,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Orden>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Cargando();
          }
          if (snapshot.hasError) {
            return VistaError(
              mensaje: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Error al cargar los pedidos.',
              onReintentar: () => setState(() => _futuro = _cargar()),
            );
          }
          final pedidos = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _futuro = _cargar()),
            child: pedidos.isEmpty
                ? ListView(children: const [SinDatos()])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: pedidos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = pedidos[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primario,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.shopping_cart),
                          ),
                          title: Text(
                            p.nombreCliente ?? '---',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primario,
                            ),
                          ),
                          subtitle: Text(
                            '${p.fechaPedido ?? ''}\nUnidades: ${p.unidades}',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _colorEstado(p.estadoProd)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  p.estadoProd ?? '---',
                                  style: TextStyle(
                                    color: _colorEstado(p.estadoProd),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    _abrirFormulario(orden: p),
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

class FormularioPedidoScreen extends StatefulWidget {
  const FormularioPedidoScreen({super.key, this.orden});

  final Orden? orden;

  @override
  State<FormularioPedidoScreen> createState() => _FormularioPedidoScreenState();
}

class _FormularioPedidoScreenState extends State<FormularioPedidoScreen> {
  String? _idCliente;
  String _fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _estado;
  List<Cliente> _clientes = [];
  bool _enviando = false;
  bool _cargandoOpciones = true;

  static const _estados = ['En proceso', 'Entregado', 'Cancelado'];

  @override
  void initState() {
    super.initState();
    final o = widget.orden;
    _idCliente = o?.idCliente;
    _estado = o?.estadoProd;
    if (o?.fechaPedido != null && o!.fechaPedido!.isNotEmpty) {
      _fecha = o.fechaPedido!;
    }
    _cargarOpciones();
  }

  Future<void> _cargarOpciones() async {
    try {
      final api = context.read<ApiClient>();
      final data = await api.listarClientes();
      if (!mounted) return;
      setState(() {
        _clientes = data
            .map((c) => Cliente.fromJson(c as Map<String, dynamic>))
            .toList();
        _cargandoOpciones = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoOpciones = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final inicial = DateTime.tryParse(_fecha) ?? hoy;
    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (elegida != null) {
      setState(() => _fecha = DateFormat('yyyy-MM-dd').format(elegida));
    }
  }

  Future<void> _guardar() async {
    if (_idCliente == null || _estado == null) {
      _mostrar('Selecciona el cliente y el estado.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final api = context.read<ApiClient>();
      final user = context.read<AuthProvider>().user;
      if (widget.orden == null) {
        await api.crearOrden({
          'idCliente': _idCliente,
          'idUsuario_Admin': user?.idUsuario,
          'fechaPedido': _fecha,
          'estadoProd': _estado,
        });
        _mostrar('Pedido creado correctamente.');
      } else {
        await api.actualizarOrden(widget.orden!.idOrden, {
          'estadoProd': _estado,
        });
        _mostrar('Pedido actualizado correctamente.');
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
    final esNuevo = widget.orden == null;
    return Scaffold(
      appBar: AppBar(title: Text(esNuevo ? 'Nuevo pedido' : 'Editar pedido')),
      body: _cargandoOpciones
          ? const Cargando()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _idCliente,
                    decoration: const InputDecoration(
                      labelText: 'Cliente *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: _clientes
                        .map((c) => DropdownMenuItem(
                              value: c.idCliente,
                              child: Text(c.nombreCliente),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _idCliente = v),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _seleccionarFecha,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha del pedido *',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(_fecha),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _estado,
                    decoration: const InputDecoration(
                      labelText: 'Estado de producción *',
                      prefixIcon: Icon(Icons.fact_check_outlined),
                    ),
                    items: _estados
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _estado = v),
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
                        : Text(esNuevo ? 'Crear pedido' : 'Guardar cambios'),
                  ),
                ],
              ),
            ),
    );
  }
}
