class Insumo {
  const Insumo({
    required this.idInsumo,
    required this.nombreInsumo,
    this.idCategoria,
    this.nombreCategoria,
    this.idUnidad,
    this.nombreUnidad,
    this.cantidad,
  });

  final String idInsumo;
  final String nombreInsumo;
  final String? idCategoria;
  final String? nombreCategoria;
  final String? idUnidad;
  final String? nombreUnidad;
  final double? cantidad;

  factory Insumo.fromJson(Map<String, dynamic> json) => Insumo(
        idInsumo: json['idInsumo'] ?? '',
        nombreInsumo: json['nombreInsumo'] ?? '',
        idCategoria: json['idCategoria'],
        nombreCategoria: json['nombreCategoria'],
        idUnidad: json['idUnidad'],
        nombreUnidad: json['nombreUnidad'],
        cantidad: (json['cantidad'] as num?)?.toDouble(),
      );
}
