/// Especie, raza, dueño y usuario: catálogos que usan los formularios.
/// Se leen con cuidado (`?? `) por si algún campo de la API se llama distinto.
class Especie {
  final int id;
  final String nombre;
  const Especie(this.id, this.nombre);
  factory Especie.fromJson(Map<String, dynamic> j) => Especie(j['id'] as int, j['nombre'] as String);
}

class Raza {
  final int id;
  final String nombre;
  const Raza(this.id, this.nombre);
  factory Raza.fromJson(Map<String, dynamic> j) => Raza(j['id'] as int, j['nombre'] as String);
}

class Dueno {
  final int id;
  final String nombre;
  final String? telefono;
  final String? direccion;
  const Dueno({required this.id, required this.nombre, this.telefono, this.direccion});
  factory Dueno.fromJson(Map<String, dynamic> j) => Dueno(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        telefono: j['telefono'] as String?,
        direccion: j['direccion'] as String?,
      );
}

/// Usuario de la API (UsuarioResponse). Por ahora se usa para elegir técnicos.
class Usuario {
  final String id;
  final String nombre;
  final String? email;
  final String? rol;
  final bool activo;
  final String? zonaNombre;
  final String? medicoId;
  final String? medicoNombre;

  const Usuario({
    required this.id,
    required this.nombre,
    this.email,
    this.rol,
    this.activo = true,
    this.zonaNombre,
    this.medicoId,
    this.medicoNombre,
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'].toString(),
        nombre: (j['nombreCompleto'] ?? j['nombre'] ?? j['email'] ?? '').toString(),
        email: j['email'] as String?,
        rol: j['rol']?.toString(),
        activo: j['activo'] as bool? ?? true,
        zonaNombre: j['zonaNombre'] as String?,
        medicoId: j['medicoId']?.toString(),
        medicoNombre: j['medicoNombre'] as String?,
      );
}
