class Cliente {
  const Cliente({required this.idCliente, required this.nombreCliente});

  final String idCliente;
  final String nombreCliente;

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        idCliente: json['idCliente'] ?? '',
        nombreCliente: json['nombreCliente'] ?? '',
      );
}
