/// Datos que devuelve POST /api/auth/login.
class Sesion {
  final String token;
  final DateTime expira;
  final String usuarioId;
  final String nombre;
  final String rol;

  const Sesion({
    required this.token,
    required this.expira,
    required this.usuarioId,
    required this.nombre,
    required this.rol,
  });

  factory Sesion.fromJson(Map<String, dynamic> json) => Sesion(
    token: json['token'] as String,
    expira: DateTime.parse(json['expira'] as String),
    usuarioId: json['usuarioId'].toString(),
    nombre: json['nombre'] as String,
    rol: json['rol'] as String,
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'expira': expira.toIso8601String(),
    'usuarioId': usuarioId,
    'nombre': nombre,
    'rol': rol,
  };

  bool get vencida => DateTime.now().isAfter(expira);
}
