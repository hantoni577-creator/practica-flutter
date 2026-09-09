// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;

Future<void> exportarReporte(
    http.Response res,
    String nombreBase, {
      required void Function(String mensaje) onError,
    }) async {
  try {
    final bytes = res.bodyBytes;
    final blob = html.Blob(
      [bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '$nombreBase.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    onError('Error al descargar el archivo Excel: $e');
  }
}
