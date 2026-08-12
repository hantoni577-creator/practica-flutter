class DetalleOrden {
  const DetalleOrden({
    this.idDetalle,
    this.idProducto,
    this.nombreProducto,
    this.cantidadTotal,
  });

  final String? idDetalle;
  final String? idProducto;
  final String? nombreProducto;
  final int? cantidadTotal;

  factory DetalleOrden.fromJson(Map<String, dynamic> json) => DetalleOrden(
        idDetalle: json['idDetalle'],
        idProducto: json['idProducto'],
        nombreProducto: json['nombreProducto'],
        cantidadTotal: json['cantidadTotal'] as int?,
      );
}

class Orden {
  const Orden({
    required this.idOrden,
    this.idCliente,
    this.nombreCliente,
    this.idUsuarioAdmin,
    this.fechaPedido,
    this.estadoProd,
    this.detalles = const [],
    this.unidades = 0,
  });

  final String idOrden;
  final String? idCliente;
  final String? nombreCliente;
  final String? idUsuarioAdmin;
  final String? fechaPedido;
  final String? estadoProd;
  final List<DetalleOrden> detalles;
  final int unidades;

  factory Orden.fromJson(Map<String, dynamic> json) => Orden(
        idOrden: json['idOrden'] ?? '',
        idCliente: json['idCliente'],
        nombreCliente: json['nombreCliente'],
        idUsuarioAdmin: json['idUsuario_Admin'],
        fechaPedido: json['fechaPedido'],
        estadoProd: json['estadoProd'],
        detalles: ((json['detalles'] as List<dynamic>?) ?? const [])
            .map((d) => DetalleOrden.fromJson(d as Map<String, dynamic>))
            .toList(),
        unidades: (json['unidades'] as num?)?.toInt() ?? 0,
      );
}
