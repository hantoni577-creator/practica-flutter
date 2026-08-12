class Producto {
  const Producto({required this.idProducto, required this.nombreProducto});

  final String idProducto;
  final String nombreProducto;

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        idProducto: json['idProducto'] ?? '',
        nombreProducto: json['nombreProducto'] ?? '',
      );
}
