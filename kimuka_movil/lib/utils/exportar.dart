import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportarReporte(
  http.Response res,
  String nombreBase, {
  required void Function(String mensaje) onError,
}) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final archivo = File('${dir.path}/$nombreBase.xlsx');
    await archivo.writeAsBytes(res.bodyBytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            archivo.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'Reporte Kimuka',
      ),
    );
  } catch (_) {
    onError('No se pudo exportar el reporte.');
  }
}
