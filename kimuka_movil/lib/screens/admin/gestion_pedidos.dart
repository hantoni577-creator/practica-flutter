import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
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
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(title: const Text('Gestión de pedidos')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.acento,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nuevo Pedido',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _abrirFormulario(),
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
                ? ListView(children: const [
              SinDatos(mensaje: 'No hay pedidos registrados.')
            ])
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: pedidos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final p = pedidos[i];

                // Extraer datos del primer detalle
                final primerDetalle = (p.detalles.isNotEmpty)
                    ? p.detalles.first as Map<String, dynamic>
                    : null;
                final nombrePrenda =
                    primerDetalle?['nombreProducto'] ?? 'Prenda general';
                final talla = primerDetalle?['talla'] ?? 'M';
                final colorPrenda = primerDetalle?['color'] ?? 'General';
                final cantidadPrenda =
                    primerDetalle?['cantidadTotal'] ?? p.unidades;

                final colorBadge = _colorEstado(p.estadoProd);

                return Card(
                  elevation: 0,
                  color: AppTheme.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Cabecera: Cliente y Estado
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.bgInput,
                              child: const Icon(Icons.person,
                                  color: AppTheme.textPrimary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.nombreCliente ?? 'Cliente sin nombre',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (p.telefonoCliente != null &&
                                      p.telefonoCliente!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined,
                                            size: 13,
                                            color: AppTheme.textoSecundario),
                                        const SizedBox(width: 4),
                                        Text(
                                          p.telefonoCliente!,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textoSecundario),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (p.correoCliente != null &&
                                      p.correoCliente!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.mail_outline,
                                            size: 13,
                                            color: AppTheme.textoSecundario),
                                        const SizedBox(width: 4),
                                        Text(
                                          p.correoCliente!,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textoSecundario),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: colorBadge.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: colorBadge, width: 0.8),
                              ),
                              child: Text(
                                p.estadoProd ?? 'En proceso',
                                style: TextStyle(
                                  color: colorBadge,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),

                        // 2. Ficha de la Prenda
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgInput,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.checkroom,
                                      size: 18, color: AppTheme.acento),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      nombrePrenda,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$cantidadPrenda unid.',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.acento,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _badgeInfo('Talla: $talla'),
                                  const SizedBox(width: 8),
                                  _badgeInfo('Color: $colorPrenda'),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 3. Fecha y Botón Editar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 14,
                                    color: AppTheme.textoSecundario),
                                const SizedBox(width: 6),
                                Text(
                                  p.fechaPedido ?? 'Fecha no registrada',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textoSecundario,
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppTheme.bgInput,
                                foregroundColor: AppTheme.textPrimary,
                                side: const BorderSide(
                                    color: AppTheme.borderColor),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined,
                                  size: 16, color: AppTheme.acento),
                              label: const Text(
                                'Editar',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _abrirFormulario(orden: p),
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

  Widget _badgeInfo(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12, color: AppTheme.textoSecundario),
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
  final _nombreClienteCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _productoCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');

  static const _tallas = [
    '5XS', '4XS', '3XS', '2XS', 'XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL'
  ];
  String _tallaSeleccionada = 'M';

  static const _colores = [
    'Negro', 'Blanco', 'Gris', 'Azul', 'Azul Oscuro', 'Rojo', 'Verde',
    'Amarillo', 'Beige', 'Café', 'Rosado', 'Morado', 'Naranja'
  ];
  String _colorSeleccionado = 'Negro';

  String _fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _estado = 'En proceso';
  bool _enviando = false;

  static const _estados = ['En proceso', 'Entregado', 'Cancelado'];

  final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    if (widget.orden != null) {
      _estado = widget.orden!.estadoProd ?? 'En proceso';
      _fecha = widget.orden!.fechaPedido ?? _fecha;
    }
  }

  @override
  void dispose() {
    _nombreClienteCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _productoCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final esEdicion = widget.orden != null;

    if (!esEdicion) {
      final nombre = _nombreClienteCtrl.text.trim();
      final correo = _correoCtrl.text.trim().toLowerCase();
      final producto = _productoCtrl.text.trim();
      final cantidadTexto = _cantidadCtrl.text.trim();

      if (nombre.isEmpty) {
        _mostrar('Ingresa el nombre del cliente (solo letras).');
        return;
      }

      if (producto.isEmpty) {
        _mostrar('Ingresa el nombre de la prenda o producto a confeccionar.');
        return;
      }

      if (correo.isNotEmpty) {
        if (correo.length > 25) {
          _mostrar('El correo no puede tener más de 25 caracteres.');
          return;
        }
        if (!_emailRegex.hasMatch(correo)) {
          _mostrar('El formato de correo no es válido (debe tener @ y terminar en .com, .co, etc.).');
          return;
        }
      }

      final cantidad = int.tryParse(cantidadTexto);
      if (cantidad == null || cantidad <= 0) {
        _mostrar('Ingresa una cantidad de unidades válida (número entero mayor a 0).');
        return;
      }
    }

    setState(() => _enviando = true);
    try {
      final api = context.read<ApiClient>();
      final user = context.read<AuthProvider>().user;

      if (!esEdicion) {
        await api.request('/api/ordenes', method: 'POST', body: {
          'nombreCliente': _nombreClienteCtrl.text.trim(),
          'telefono': _telefonoCtrl.text.trim(),
          'correo': _correoCtrl.text.trim().toLowerCase(),
          'nombreProducto': _productoCtrl.text.trim(),
          'talla': _tallaSeleccionada,
          'color': _colorSeleccionado,
          'cantidadTotal': int.parse(_cantidadCtrl.text.trim()),
          'idUsuario_Admin': user?.idUsuario,
          'fechaPedido': _fecha,
          'estadoProd': _estado,
        });
        _mostrar('Pedido registrado exitosamente.');
      } else {
        await api.actualizarOrden(widget.orden!.idOrden, {
          'estadoProd': _estado,
        });
        _mostrar('Pedido actualizado exitosamente.');
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      _mostrar(e.message);
    } catch (e) {
      _mostrar('Error al procesar el pedido: $e');
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
    final esNuevo = widget.orden == null;

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: Text(esNuevo ? 'Nuevo Pedido' : 'Editar Pedido'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (esNuevo) ...[
                  const Text(
                    'Datos del Cliente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nombreClienteCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Cliente *',
                      hintText: 'Solo letras',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.textoSecundario),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 15,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      hintText: 'Máximo 15 números',
                      counterText: '',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textoSecundario),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 25,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      hintText: 'ejemplo@correo.com',
                      counterText: '',
                      prefixIcon: Icon(Icons.mail_outline, color: AppTheme.textoSecundario),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Prenda / Producto a Confeccionar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _productoCtrl,
                    maxLength: 30,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Prenda o producto a realizar *',
                      hintText: 'Ej. Camisa, Pantalón (máx. 30 letras)',
                      counterText: '',
                      prefixIcon: Icon(Icons.checkroom, color: AppTheme.textoSecundario),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _tallaSeleccionada,
                          dropdownColor: AppTheme.bgCard,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Talla *',
                            prefixIcon: Icon(Icons.straighten, color: AppTheme.textoSecundario),
                          ),
                          items: _tallas
                              .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _tallaSeleccionada = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _colorSeleccionado,
                          dropdownColor: AppTheme.bgCard,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Color *',
                            prefixIcon: Icon(Icons.color_lens_outlined, color: AppTheme.textoSecundario),
                          ),
                          items: _colores
                              .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _colorSeleccionado = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cantidadCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Cantidad de unidades *',
                      hintText: 'Solo números enteros',
                      counterText: '',
                      prefixIcon: Icon(Icons.format_list_numbered, color: AppTheme.textoSecundario),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha del pedido (Automática)',
                    prefixIcon: Icon(Icons.calendar_today, color: AppTheme.textoSecundario),
                  ),
                  child: Text(_fecha, style: const TextStyle(color: AppTheme.textPrimary)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _estado,
                  dropdownColor: AppTheme.bgCard,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Estado de producción *',
                    prefixIcon: Icon(Icons.fact_check_outlined, color: AppTheme.textoSecundario),
                  ),
                  items: _estados
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => _estado = v!),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _enviando ? null : _guardar,
                  child: _enviando
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                      : Text(esNuevo ? 'Crear pedido' : 'Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}