import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/insumo.dart';

class InventarioProvider with ChangeNotifier {
  final ApiClient _apiClient;

  InventarioProvider(this._apiClient);

  List<Insumo> _insumos = [];
  bool _isLoading = false;
  String? _error;

  List<Insumo> get insumos => _insumos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchInventario() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _apiClient.listarInsumos();
      _insumos = res
          .map((i) => Insumo.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Error al cargar el inventario.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}