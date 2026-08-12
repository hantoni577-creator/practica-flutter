class Usuario {
  const Usuario({
    required this.idUsuario,
    required this.nombre,
    this.pNombre,
    this.sNombre,
    this.pApellido,
    this.sApellido,
    required this.correo,
    required this.idRol,
    this.rol,
    this.idEstado,
    this.estado,
  });

  final String idUsuario;
  final String nombre;
  final String? pNombre;
  final String? sNombre;
  final String? pApellido;
  final String? sApellido;
  final String correo;
  final String idRol;
  final String? rol;
  final String? idEstado;
  final String? estado;

  bool get activo => idEstado == 'EST-001';

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        idUsuario: json['idUsuario'] ?? '',
        nombre: json['nombre'] ?? '',
        pNombre: json['pNombre'],
        sNombre: json['sNombre'],
        pApellido: json['pApellido'],
        sApellido: json['sApellido'],
        correo: json['correo'] ?? '',
        idRol: json['idRol'] ?? '',
        rol: json['rol'],
        idEstado: json['idEstado'],
        estado: json['estado'],
      );
}
