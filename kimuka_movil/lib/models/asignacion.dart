class Asignacion {
  const Asignacion({
    required this.idAsignacion,
    this.idUsuarioEmpleado,
    this.nombreEmpleado,
    this.idInsumo,
    this.nombreInsumo,
    this.cantidad,
    this.fechaAsignacion,
    this.estado,
  });

  final String idAsignacion;
  final String? idUsuarioEmpleado;
  final String? nombreEmpleado;
  final String? idInsumo;
  final String? nombreInsumo;
  final double? cantidad;
  final String? fechaAsignacion;
  final String? estado;

  bool get completada => estado == 'Completada';

  factory Asignacion.fromJson(Map<String, dynamic> json) => Asignacion(
        idAsignacion: json['idAsignacion'] ?? '',
        idUsuarioEmpleado: json['idUsuario_Empleado'],
        nombreEmpleado: json['nombreEmpleado'],
        idInsumo: json['idInsumo'],
        nombreInsumo: json['nombreInsumo'],
        cantidad: (json['cantidad'] as num?)?.toDouble(),
        fechaAsignacion: json['fechaAsignacion'],
        estado: json['estado'],
      );
}
