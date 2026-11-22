/// Servicio del catálogo (GET /api/servicios). El enunciado define precio y duración [p2].
class Servicio {
  final int id;
  final String nombre;
  final double? precio;
  final int? duracionMinutos;

  const Servicio({required this.id, required this.nombre, this.precio, this.duracionMinutos});

  factory Servicio.fromJson(Map<String, dynamic> j) {
    // Busca la duración aunque el campo se llame distinto (duracionMinutos, duracionMin, duracion).
    final claveDuracion = j.keys.firstWhere(
      (k) => k.toLowerCase().startsWith('duracion'),
      orElse: () => '',
    );
    return Servicio(
      id: j['id'] as int,
      nombre: j['nombre'] as String,
      precio: (j['precio'] as num?)?.toDouble(),
      duracionMinutos: claveDuracion.isEmpty ? null : (j[claveDuracion] as num?)?.toInt(),
    );
  }

  /// Ejemplo: "Vacunación · Q150.00 · 30 min"
  String get descripcion {
    final partes = [nombre];
    if (precio != null) partes.add('Q${precio!.toStringAsFixed(2)}');
    if (duracionMinutos != null) partes.add('$duracionMinutos min');
    return partes.join(' · ');
  }
}
