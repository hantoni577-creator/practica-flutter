class UnidadMedida {
  const UnidadMedida({required this.idUnidad, required this.nombreUnidad});

  final String idUnidad;
  final String nombreUnidad;

  factory UnidadMedida.fromJson(Map<String, dynamic> json) => UnidadMedida(
        idUnidad: json['idUnidad'] ?? '',
        nombreUnidad: json['nombreUnidad'] ?? '',
      );
}
