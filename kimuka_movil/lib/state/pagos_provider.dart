import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/pago.dart';

class PagosProvider with ChangeNotifier {
  final ApiClient _apiClient;

  PagosProvider(this._apiClient);

  List<Pago> _pagos = [];
  bool _isLoading = false;
  String? _error;

  List<Pago> get pagos => _pagos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPagos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiClient.listarPagos();
      _pagos = data
          .map((p) => Pago.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Error al cargar los pagos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Alias para mantener compatibilidad si se llama como pendientes
  Future<void> fetchPagosPendientes() async => fetchPagos();

  Future<bool> crearPago(Map<String, dynamic> datos) async {
    try {
      await _apiClient.crearPago(datos);
      await fetchPagos();
      return true;
    } catch (e) {
      _error = e is ApiException ? e.message : 'Error al registrar el pago.';
      notifyListeners();
      return false;
    }
  }
}