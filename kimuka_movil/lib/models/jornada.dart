class Jornada {
  const Jornada({
    required this.idJornada,
    this.idUsuarioEmpleado,
    this.nombreEmpleado,
    this.fecha,
    this.hInicio,
    this.hFin,
    this.horas,
    this.anio,
    this.mes,
  });

  final String idJornada;
  final String? idUsuarioEmpleado;
  final String? nombreEmpleado;
  final String? fecha;
  final String? hInicio;
  final String? hFin;
  final double? horas;
  final String? anio;
  final String? mes;

  bool get activa => hInicio != null && (hFin == null || hFin!.isEmpty);

  factory Jornada.fromJson(Map<String, dynamic> json) => Jornada(
        idJornada: json['idJornada'] ?? '',
        idUsuarioEmpleado: json['idUsuario_Empleado'],
        nombreEmpleado: json['nombreEmpleado'],
        fecha: json['fecha'],
        hInicio: json['hInicio'],
        hFin: json['hFin'],
        horas: (json['horas'] as num?)?.toDouble(),
        anio: json['anio'],
        mes: json['mes'],
      );
}
