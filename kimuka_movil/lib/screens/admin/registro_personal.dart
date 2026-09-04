import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/rol.dart';
import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';
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
  final _password = TextEditingController();
  final _confirmarPassword = TextEditingController();

  String? _idRol;
  bool _enviando = false;
  bool _ocultarPass = true;
  bool _ocultarConfirmPass = true;
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
    _password.dispose();
    _confirmarPassword.dispose();
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
    final pass = _password.text.trim();
    final confirmPass = _confirmarPassword.text.trim();

    if (_pNombre.text.trim().isEmpty ||
        _pApellido.text.trim().isEmpty ||
        _correo.text.trim().isEmpty ||
        _idRol == null ||
        pass.isEmpty) {
      _mostrar('Completa todos los campos obligatorios (*).');
      return;
    }

    if (pass != confirmPass) {
      _mostrar('Las contraseñas no coinciden.');
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
        'password': pass, // Enviamos la contraseña digitada
        'idRol': _idRol,
        'idUsuario_Admin': user?.idUsuario,
      });

      if (!mounted) return;
      _mostrar('Usuario creado correctamente.');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        title: const Text('Registrar Nuevo Empleado'),
        centerTitle: false,
      ),
      body: _cargandoRoles
          ? const Cargando()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ingresa los datos personales y credenciales de acceso:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textoSecundario,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pNombre,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Primer nombre *',
                          prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textoSecundario),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _sNombre,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Segundo nombre',
                          prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textoSecundario),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pApellido,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Primer apellido *',
                          prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textoSecundario),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _sApellido,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Segundo apellido',
                          prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textoSecundario),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _correo,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico *',
                    prefixIcon: Icon(Icons.mail_outline, color: AppTheme.textoSecundario),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _idRol,
                  dropdownColor: AppTheme.bgCard,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Rol / Perfil *',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: AppTheme.textoSecundario),
                  ),
                  items: _roles
                      .map((r) => DropdownMenuItem(
                    value: r.idRol,
                    child: Text(
                      r.nombreRol,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => _idRol = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _password,
                        obscureText: _ocultarPass,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Contraseña *',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textoSecundario),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarPass ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.textoSecundario,
                            ),
                            onPressed: () => setState(() => _ocultarPass = !_ocultarPass),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _confirmarPassword,
                        obscureText: _ocultarConfirmPass,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña *',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textoSecundario),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarConfirmPass ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.textoSecundario,
                            ),
                            onPressed: () => setState(() => _ocultarConfirmPass = !_ocultarConfirmPass),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _enviando ? null : _guardar,
                  child: _enviando
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                      : const Text('Registrar Usuario'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
