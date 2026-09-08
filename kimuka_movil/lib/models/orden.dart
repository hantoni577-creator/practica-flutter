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
  final String idOrden;
  final String? idCliente;
  final String? nombreCliente;
  final String? telefonoCliente;
  final String? correoCliente;
  final String? idUsuarioAdmin;
  final String? fechaPedido;
  final String? estadoProd;
  final int unidades;
  final List<dynamic> detalles;

  Orden({
    required this.idOrden,
    this.idCliente,
    this.nombreCliente,
    this.telefonoCliente,
    this.correoCliente,
    this.idUsuarioAdmin,
    this.fechaPedido,
    this.estadoProd,
    this.unidades = 0,
    this.detalles = const [],
  });

  factory Orden.fromJson(Map<String, dynamic> json) {
    return Orden(
      idOrden: json['idOrden']?.toString() ?? '',
      idCliente: json['idCliente']?.toString(),
      nombreCliente: json['nombreCliente']?.toString(),
      telefonoCliente: json['telefonoCliente']?.toString(),
      correoCliente: json['correoCliente']?.toString(),
      idUsuarioAdmin: json['idUsuario_Admin']?.toString(),
      fechaPedido: json['fechaPedido']?.toString(),
      estadoProd: json['estadoProd']?.toString(),
      unidades: (json['unidades'] as num?)?.toInt() ?? 0,
      detalles: json['detalles'] as List<dynamic>? ?? [],
    );
  }
}
