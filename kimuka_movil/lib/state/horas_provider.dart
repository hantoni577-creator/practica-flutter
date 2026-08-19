import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/jornada.dart';

class HorasProvider with ChangeNotifier {
  final ApiClient _apiClient;

  HorasProvider(this._apiClient);

  List<Jornada> _jornadas = [];
  List<Jornada> _todasLasJornadas = [];
  Map<String, dynamic> _calculo = {};
  bool _isLoading = false;
  String? _error;

  List<Jornada> get jornadas => _jornadas;
  List<Jornada> get todasLasJornadas => _todasLasJornadas;
  Map<String, dynamic> get calculo => _calculo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMisHoras(String idUsuario) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _apiClient.jornadasPorEmpleado(idUsuario);
      _calculo = await _apiClient.calcularPagoJornada(idUsuario);
      _jornadas = ((res['jornadas'] as List<dynamic>?) ?? const [])
          .map((j) => Jornada.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Error al cargar tus horas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> crearJornada(Map<String, dynamic> datos, String idUsuario) async {
    try {
      await _apiClient.crearJornada(datos);
      await fetchMisHoras(idUsuario);
      return true;
    } catch (e) {
      _error = e is ApiException ? e.message : 'Error al registrar la jornada.';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchHorasAdmin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiClient.listarJornadas();
      _todasLasJornadas = data
          .map((j) => Jornada.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Error al cargar las jornadas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}