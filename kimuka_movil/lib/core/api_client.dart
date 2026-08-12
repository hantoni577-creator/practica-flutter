import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'session_manager.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.session);

  final SessionManager session;

  String get baseUrl => ApiConfig.baseUrl;

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final t = session.token;
    if (t != null && t.isNotEmpty) {
      headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  dynamic _parse(http.Response res) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      data = <String, dynamic>{'message': 'Error ${res.statusCode}'};
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Error ${res.statusCode}';
      throw ApiException(msg, res.statusCode);
    }
    return data;
  }

  Future<dynamic> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: query);
    final http.Response res;
    switch (method) {
      case 'POST':
        res = await _client.post(
          uri,
          headers: _headers(),
          body: jsonEncode(body ?? {}),
        );
        break;
      case 'PUT':
        res = await _client.put(
          uri,
          headers: _headers(),
          body: jsonEncode(body ?? {}),
        );
        break;
      case 'DELETE':
        res = await _client.delete(uri, headers: _headers());
        break;
      default:
        res = await _client.get(uri, headers: _headers());
    }
    return _parse(res);
  }

  Future<http.Response> download(
    String endpoint, {
    Map<String, String>? query,
  }) async {
    final uri =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: query);
    final res = await _client.get(uri, headers: _headers(json: false));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('Error al descargar (${res.statusCode})',
          res.statusCode);
    }
    return res;
  }

  late final http.Client _client = http.Client();

  Map<String, String>? _filtros({
    String? mes,
    String? anio,
    String? empleado,
    String? estado,
    String? categoria,
    String? cliente,
  }) {
    final q = <String, String>{};
    void add(String k, String? v) {
      if (v != null && v.isNotEmpty && v != 'todos') q[k] = v;
    }

    add('mes', mes);
    add('anio', anio);
    add('idUsuario_Empleado', empleado);
    add('estado', estado);
    add('categoria', categoria);
    add('cliente', cliente);
    return q.isEmpty ? null : q;
  }

  Map<String, dynamic> _data(dynamic res) => res['data'] as Map<String, dynamic>;

  List<dynamic> _lista(dynamic res) =>
      res['data'] as List<dynamic>? ?? const [];

  // ============================== AUTH ==============================

  Future<Map<String, dynamic>> login(String correo, String password) async {
    final res = await request(
      '/api/auth/login',
      method: 'POST',
      body: {'correo': correo, 'password': password},
    );
    return _data(res);
  }

  Future<dynamic> recuperarContrasena(String correo) =>
      request('/api/auth/recuperar-contrasena',
          method: 'POST', body: {'correo': correo});

  Future<dynamic> verificarToken() => request('/api/auth/verificar-token');

  // ============================== USUARIOS ==============================

  Future<List<dynamic>> listarUsuarios() async =>
      _lista(await request('/api/usuarios'));

  Future<Map<String, dynamic>> obtenerUsuario(String id) async =>
      _data(await request('/api/usuarios/$id'));

  Future<dynamic> crearUsuario(Map<String, dynamic> data) =>
      request('/api/usuarios', method: 'POST', body: data);

  Future<dynamic> actualizarUsuario(String id, Map<String, dynamic> data) =>
      request('/api/usuarios/$id', method: 'PUT', body: data);

  Future<dynamic> eliminarUsuario(String id) =>
      request('/api/usuarios/$id', method: 'DELETE');

  Future<dynamic> desactivarUsuario(String id) =>
      request('/api/usuarios/$id/desactivar', method: 'PUT');

  // ============================== EMPLEADOS ==============================

  Future<List<dynamic>> listarEmpleados() async =>
      _lista(await request('/api/empleados'));

  // ============================== ROLES ==============================

  Future<List<dynamic>> listarRoles() async =>
      _lista(await request('/api/roles'));

  // ============================== INSUMOS ==============================

  Future<List<dynamic>> listarInsumos() async =>
      _lista(await request('/api/insumos'));

  Future<dynamic> crearInsumo(Map<String, dynamic> data) =>
      request('/api/insumos', method: 'POST', body: data);

  Future<dynamic> actualizarInsumo(String id, Map<String, dynamic> data) =>
      request('/api/insumos/$id', method: 'PUT', body: data);

  Future<dynamic> eliminarInsumo(String id) =>
      request('/api/insumos/$id', method: 'DELETE');

  // ============================== ASIGNACIONES ==============================

  Future<List<dynamic>> listarAsignaciones() async =>
      _lista(await request('/api/asignaciones'));

  Future<dynamic> crearAsignacion(Map<String, dynamic> data) =>
      request('/api/asignaciones', method: 'POST', body: data);

  Future<List<dynamic>> asignacionesPorEmpleado(String id) async =>
      _lista(await request('/api/asignaciones/empleado/$id'));

  Future<dynamic> cambiarEstadoAsignacion(
          String id, Map<String, dynamic> data) =>
      request('/api/asignaciones/$id/estado', method: 'PUT', body: data);

  // ============================== CATEGORIAS ==============================

  Future<List<dynamic>> listarCategorias() async =>
      _lista(await request('/api/categorias'));

  // ============================== UNIDADES DE MEDIDA ==============================

  Future<List<dynamic>> listarUnidadesMedida() async =>
      _lista(await request('/api/unidades-medida'));

  // ============================== ORDENES ==============================

  Future<List<dynamic>> listarOrdenes() async =>
      _lista(await request('/api/ordenes'));

  Future<Map<String, dynamic>> obtenerOrden(String id) async =>
      _data(await request('/api/ordenes/$id'));

  Future<dynamic> crearOrden(Map<String, dynamic> data) =>
      request('/api/ordenes', method: 'POST', body: data);

  Future<dynamic> actualizarOrden(String id, Map<String, dynamic> data) =>
      request('/api/ordenes/$id', method: 'PUT', body: data);

  // ============================== JORNADAS ==============================

  Future<List<dynamic>> listarJornadas() async =>
      _lista(await request('/api/jornadas'));

  Future<dynamic> crearJornada(Map<String, dynamic> data) =>
      request('/api/jornadas', method: 'POST', body: data);

  Future<dynamic> finalizarJornada(String id, Map<String, dynamic> data) =>
      request('/api/jornadas/$id', method: 'PUT', body: data);

  Future<Map<String, dynamic>> jornadasPorEmpleado(String id) async =>
      _data(await request('/api/jornadas/empleado/$id'));

  Future<Map<String, dynamic>> calcularPagoJornada(String id) async =>
      _data(await request('/api/jornadas/calcular-pago/$id'));

  // ============================== PAGOS ==============================

  Future<List<dynamic>> listarPagos() async =>
      _lista(await request('/api/pagos'));

  Future<dynamic> crearPago(Map<String, dynamic> data) =>
      request('/api/pagos', method: 'POST', body: data);

  Future<dynamic> aprobarPago(String id, Map<String, dynamic> data) =>
      request('/api/pagos/$id', method: 'PUT', body: data);

  // ============================== METODOS DE PAGO ==============================

  Future<List<dynamic>> listarMetodosPago() async =>
      _lista(await request('/api/metodos-pago'));

  // ============================== CLIENTES ==============================

  Future<List<dynamic>> listarClientes() async =>
      _lista(await request('/api/clientes'));

  Future<dynamic> crearCliente(Map<String, dynamic> data) =>
      request('/api/clientes', method: 'POST', body: data);

  // ============================== PRODUCTOS ==============================

  Future<List<dynamic>> listarProductos() async =>
      _lista(await request('/api/productos'));

  Future<dynamic> crearProducto(Map<String, dynamic> data) =>
      request('/api/productos', method: 'POST', body: data);

  // ============================== REPORTES ==============================

  Future<List<dynamic>> reporteHoras({
    String? mes,
    String? anio,
    String? empleado,
  }) async =>
      _lista(await request('/api/reportes/horas',
          query: _filtros(mes: mes, anio: anio, empleado: empleado)));

  Future<http.Response> exportarHoras({String? mes, String? anio}) =>
      download('/api/reportes/horas/excel',
          query: _filtros(mes: mes, anio: anio));

  Future<List<dynamic>> reporteTrabajos({
    String? mes,
    String? anio,
    String? empleado,
    String? estado,
  }) async =>
      _lista(await request('/api/reportes/trabajos',
          query: _filtros(mes: mes, anio: anio, empleado: empleado, estado: estado)));

  Future<http.Response> exportarTrabajos({String? mes, String? anio}) =>
      download('/api/reportes/trabajos/excel',
          query: _filtros(mes: mes, anio: anio));

  Future<List<dynamic>> reporteProduccion({
    String? mes,
    String? anio,
    String? cliente,
    String? estado,
  }) async =>
      _lista(await request('/api/reportes/produccion',
          query: _filtros(mes: mes, anio: anio, cliente: cliente, estado: estado)));

  Future<http.Response> exportarProduccion({String? mes, String? anio}) =>
      download('/api/reportes/produccion/excel',
          query: _filtros(mes: mes, anio: anio));

  Future<List<dynamic>> reporteMateriasPrimas({String? categoria}) async =>
      _lista(await request('/api/reportes/materias-primas',
          query: _filtros(categoria: categoria)));

  Future<http.Response> exportarMateriasPrimas({String? categoria}) =>
      download('/api/reportes/materias-primas/excel',
          query: _filtros(categoria: categoria));
}
