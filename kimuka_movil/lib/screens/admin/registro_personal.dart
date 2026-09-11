import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/rol.dart';
import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

// Formateador que fuerza mayúsculas en tiempo real mientras el usuario escribe
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

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

  // Solo letras (con acentos y ñ)
  static final _soloLetrasRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ]+$');

  // Correo con @ y extensión de dominio (.com, .co, etc.)
  static final _emailRegex =
  RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  // Solo números
  static final _soloNumerosRegex = RegExp(r'^[0-9]+$');

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
    final pNom = _pNombre.text.trim().toUpperCase();
    final sNom = _sNombre.text.trim().toUpperCase();
    final pApe = _pApellido.text.trim().toUpperCase();
    final sApe = _sApellido.text.trim().toUpperCase();
    final correo = _correo.text.trim().toLowerCase();
    final pass = _password.text.trim();
    final confirmPass = _confirmarPassword.text.trim();

    // 1. Campos obligatorios
    if (pNom.isEmpty || pApe.isEmpty || correo.isEmpty || _idRol == null || pass.isEmpty) {
      _mostrar('Completa todos los campos obligatorios (*).');
      return;
    }

    // 2. Validación de Primer Nombre (solo letras, máx 20)
    if (!_soloLetrasRegex.hasMatch(pNom)) {
      _mostrar('El primer nombre solo puede contener letras.');
      return;
    }
    if (pNom.length > 20) {
      _mostrar('El primer nombre no puede superar los 20 caracteres.');
      return;
    }

    // 3. Validación de Segundo Nombre (opcional, máx 20)
    if (sNom.isNotEmpty) {
      if (!_soloLetrasRegex.hasMatch(sNom)) {
        _mostrar('El segundo nombre solo puede contener letras.');
        return;
      }
      if (sNom.length > 20) {
        _mostrar('El segundo nombre no puede superar los 20 caracteres.');
        return;
      }
    }

    // 4. Validación de Primer Apellido (solo letras, máx 20)
    if (!_soloLetrasRegex.hasMatch(pApe)) {
      _mostrar('El primer apellido solo puede contener letras.');
      return;
    }
    if (pApe.length > 20) {
      _mostrar('El primer apellido no puede superar los 20 caracteres.');
      return;
    }

    // 5. Validación de Segundo Apellido (opcional, máx 20)
    if (sApe.isNotEmpty) {
      if (!_soloLetrasRegex.hasMatch(sApe)) {
        _mostrar('El segundo apellido solo puede contener letras.');
        return;
      }
      if (sApe.length > 20) {
        _mostrar('El segundo apellido no puede superar los 20 caracteres.');
        return;
      }
    }

    // 6. Validación de Correo (máx 25, con @ y dominio)
    if (correo.length > 25) {
      _mostrar('El correo no puede tener más de 25 caracteres.');
      return;
    }
    if (!_emailRegex.hasMatch(correo)) {
      _mostrar('El formato de correo es inválido (debe tener @ y dominio como .com o .co).');
      return;
    }

    // 7. Validación de Contraseña (solo números, máx 15)
    if (!_soloNumerosRegex.hasMatch(pass)) {
      _mostrar('La contraseña solo debe contener números.');
      return;
    }
    if (pass.length > 15) {
      _mostrar('La contraseña no puede tener más de 15 números.');
      return;
    }

    // 8. Coincidencia de contraseñas
    if (pass != confirmPass) {
      _mostrar('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _enviando = true);
    try {
      final api = context.read<ApiClient>();
      final user = context.read<AuthProvider>().user;

      await api.crearUsuario({
        'pNombre': pNom,
        'sNombre': sNom.isEmpty ? null : sNom,
        'pApellido': pApe,
        'sApellido': sApe.isEmpty ? null : sApe,
        'correo': correo,
        'password': pass,
        'idRol': _idRol,
        'idUsuario_Admin': user?.idUsuario,
      });

      if (!mounted) return;
      _mostrar('Usuario creado correctamente.');
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Card(
              color: AppTheme.bgCard,
              elevation: 0,
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
                      'Datos Personales y Acceso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ingresa los datos personales y credenciales de acceso:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Fila Nombres
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pNombre,
                            maxLength: 20,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]')),
                              UpperCaseTextFormatter(),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Primer nombre *',
                              hintText: 'Máx. 20 letras',
                              counterText: '',
                              prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textoSecundario),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _sNombre,
                            maxLength: 20,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]')),
                              UpperCaseTextFormatter(),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Segundo nombre',
                              hintText: 'Máx. 20 letras',
                              counterText: '',
                              prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textoSecundario),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Fila Apellidos
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pApellido,
                            maxLength: 20,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]')),
                              UpperCaseTextFormatter(),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Primer apellido *',
                              hintText: 'Máx. 20 letras',
                              counterText: '',
                              prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textoSecundario),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _sApellido,
                            maxLength: 20,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]')),
                              UpperCaseTextFormatter(),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Segundo apellido',
                              hintText: 'Máx. 20 letras',
                              counterText: '',
                              prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textoSecundario),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Correo
                    TextField(
                      controller: _correo,
                      maxLength: 25,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico *',
                        hintText: 'ejemplo@correo.com (máx. 25)',
                        counterText: '',
                        prefixIcon: Icon(Icons.mail_outline, color: AppTheme.textoSecundario),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Rol
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
                    const SizedBox(height: 14),

                    // Fila Contraseñas (solo números)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _password,
                            maxLength: 15,
                            obscureText: _ocultarPass,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Contraseña (números) *',
                              hintText: 'Máx. 15 dígitos',
                              counterText: '',
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
                            maxLength: 15,
                            obscureText: _ocultarConfirmPass,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña *',
                              hintText: 'Máx. 15 dígitos',
                              counterText: '',
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

                    // Botón blanco con texto oscuro
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _enviando ? null : _guardar,
                      child: _enviando
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                          : const Text(
                        'Registrar Usuario',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
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