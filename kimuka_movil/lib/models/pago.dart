class Pago {
  const Pago({
    required this.idPago,
    this.idJornada,
    this.idUsuarioAdmin,
    this.montoPagado,
    this.idMetodo,
    this.nombreMetodo,
    this.fechaPago,
  });

  final String idPago;
  final String? idJornada;
  final String? idUsuarioAdmin;
  final double? montoPagado;
  final String? idMetodo;
  final String? nombreMetodo;
  final String? fechaPago;

  factory Pago.fromJson(Map<String, dynamic> json) => Pago(
        idPago: json['idPago'] ?? '',
        idJornada: json['idJornada'],
        idUsuarioAdmin: json['idUsuario_Admin'],
        montoPagado: (json['montoPagado'] as num?)?.toDouble(),
        idMetodo: json['idMetodo'],
        nombreMetodo: json['nombreMetodo'],
        fechaPago: json['fechaPago'],
      );
}
