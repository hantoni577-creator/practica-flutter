class Rol {
  const Rol({required this.idRol, required this.nombreRol});

  final String idRol;
  final String nombreRol;

  factory Rol.fromJson(Map<String, dynamic> json) => Rol(
        idRol: json['idRol'] ?? '',
        nombreRol: json['nombreRol'] ?? '',
      );
}
