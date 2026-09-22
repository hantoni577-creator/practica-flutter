import 'package:http/http.dart' as http;

Future<void> exportarReporte(
    http.Response res,
    String nombreBase, {
      required void Function(String mensaje) onError,
    }) async {
  onError('La exportación a Excel no está disponible en esta plataforma');
}