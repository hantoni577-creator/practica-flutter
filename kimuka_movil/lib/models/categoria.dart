class Categoria {
  const Categoria({required this.idCategoria, required this.nombreCategoria});

  final String idCategoria;
  final String nombreCategoria;

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        idCategoria: json['idCategoria'] ?? '',
        nombreCategoria: json['nombreCategoria'] ?? '',
      );
}
