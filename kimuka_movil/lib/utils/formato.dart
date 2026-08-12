import 'package:intl/intl.dart';

String formatearMoneda(num? valor) {
  if (valor == null) return r'$ 0';
  final f = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$ ',
    decimalDigits: 0,
  );
  return f.format(valor);
}

String formatearHora(String? hora) {
  if (hora == null || hora.isEmpty) return '---';
  return hora.length >= 5 ? hora.substring(0, 5) : hora;
}

String calcularDuracion(String? hInicio, String? hFin) {
  if (hInicio == null ||
      hInicio.isEmpty ||
      hFin == null ||
      hFin.isEmpty) {
    return '---';
  }
  final inicio = _aMinutos(hInicio);
  var fin = _aMinutos(hFin);
  if (fin < inicio) fin += 1440;
  final diff = fin - inicio;
  return '${diff ~/ 60}h ${diff % 60}m';
}

int _aMinutos(String hora) {
  final partes = hora.split(':');
  if (partes.length < 2) return 0;
  final h = int.tryParse(partes[0]) ?? 0;
  final m = int.tryParse(partes[1]) ?? 0;
  return h * 60 + m;
}
