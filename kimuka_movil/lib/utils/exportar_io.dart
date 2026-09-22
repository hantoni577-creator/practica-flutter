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
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$nombreBase.xlsx');
    await file.writeAsBytes(res.bodyBytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
      ),
    );
  } catch (e) {
    onError('Error al exportar el archivo Excel: $e');
  }
}