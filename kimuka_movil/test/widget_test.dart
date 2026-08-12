import 'package:flutter_test/flutter_test.dart';

import 'package:kimuka_movil/config/api_config.dart';
import 'package:kimuka_movil/utils/formato.dart';

void main() {
  test('ApiConfig define una base URL', () {
    expect(ApiConfig.baseUrl, isNotEmpty);
  });

  test('calcularDuracion calcula horas y minutos', () {
    expect(calcularDuracion('08:00', '17:00'), '9h 0m');
    expect(calcularDuracion('22:00', '06:00'), '8h 0m');
    expect(calcularDuracion('08:00', null), '---');
  });

  test('formatearHora recorta a HH:mm', () {
    expect(formatearHora('09:05:00'), '09:05');
    expect(formatearHora(null), '---');
  });
}
