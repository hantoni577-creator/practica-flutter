class User {
  const User({
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    this.rol,
    required this.idRol,
    required this.token,
  });

  final String idUsuario;
  final String nombre;
  final String correo;
  final String? rol;
  final String idRol;
  final String token;

  bool get esAdmin => idRol == 'ROL-001';

  factory User.fromJson(Map<String, dynamic> json) => User(
        idUsuario: json['idUsuario'] ?? '',
        nombre: json['nombre'] ?? '',
        correo: json['correo'] ?? '',
        rol: json['rol'],
        idRol: json['idRol'] ?? '',
        token: json['token'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'idUsuario': idUsuario,
        'nombre': nombre,
        'correo': correo,
        'rol': rol,
        'idRol': idRol,
        'token': token,
      };
}
