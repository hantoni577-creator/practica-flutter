import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/rol.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';

class RegistroPersonalScreen extends StatefulWidget {
  const RegistroPersonalScreen({super.key});

  @override
  State<RegistroPersonalScreen> createState() => _RegistroPersonalScreenState();
}

class _RegistroPersonalScreenState extends State<RegistroPersonalScreen> {
  final _pNombre = TextEditingController();
  final _sNombre = TextEditingController();
  final _pApellido = TextEditingController();
  final _sApellido = TextEditingController();
  final _correo = TextEditingController();
  String? _idRol;
  bool _enviando = false;
  List<Rol> _roles = [];
  bool _cargandoRoles = true;

  @override
  void initState() {
    super.initState();
    _cargarRoles();
  }

  @override
  void dispose() {
    _pNombre.dispose();
    _sNombre.dispose();
    _pApellido.dispose();
    _sApellido.dispose();
    _correo.dispose();
    super.dispose();
  }

  Future<void> _cargarRoles() async {
    try {
      final api = context.read<ApiClient>();
      final data = await api.listarRoles();
      if (!mounted) return;
      setState(() {
        _roles = data
            .map((r) => Rol.fromJson(r as Map<String, dynamic>))
            .toList();
        _cargandoRoles = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoRoles = false);
    }
  }

  Future<void> _guardar() async {
    if (_pNombre.text.trim().isEmpty ||
        _pApellido.text.trim().isEmpty ||
        _correo.text.trim().isEmpty ||
        _idRol == null) {
      _mostrar('Completa los campos obligatorios.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final api = context.read<ApiClient>();
      final user = context.read<AuthProvider>().user;
      await api.crearUsuario({
        'pNombre': _pNombre.text.trim(),
        'sNombre': _sNombre.text.trim(),
        'pApellido': _pApellido.text.trim(),
        'sApellido': _sApellido.text.trim(),
        'correo': _correo.text.trim().toLowerCase(),
        'idRol': _idRol,
        'idUsuario_Admin': user?.idUsuario,
      });
      if (!mounted) return;
      _mostrar('Usuario creado correctamente. La contraseña temporal se genera automáticamente.');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de personal')),
      body: _cargandoRoles
          ? const Cargando()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'La contraseña temporal se genera automáticamente al crear el usuario.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pNombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Primer nombre *',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sNombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Segundo nombre',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pApellido,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Primer apellido *',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sApellido,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Segundo apellido',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico *',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _idRol,
                    decoration: const InputDecoration(
                      labelText: 'Rol *',
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                    items: _roles
                        .map((r) => DropdownMenuItem(
                              value: r.idRol,
                              child: Text(r.nombreRol),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _idRol = v),
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
                        : const Text('Crear usuario'),
                  ),
                ],
              ),
            ),
    );
  }
}
