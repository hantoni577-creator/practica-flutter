class MetodoPago {
  const MetodoPago({required this.idMetodo, required this.nombreMetodo});

  final String idMetodo;
  final String nombreMetodo;

  factory MetodoPago.fromJson(Map<String, dynamic> json) => MetodoPago(
        idMetodo: json['idMetodo'] ?? '',
        nombreMetodo: json['nombreMetodo'] ?? '',
      );
}
