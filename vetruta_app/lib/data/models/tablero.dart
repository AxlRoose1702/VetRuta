/// Respuesta de GET /api/tablero.
/// Cumplimiento = realizadas / (realizadas + programadas ya vencidas) (decisión del README de la API).
class Tablero {
  final int programadas;
  final int realizadas;
  final int canceladas;
  final int atrasadas;
  final double porcentajeCumplimiento;
  final List<CumplimientoTecnico> porTecnico;
  final List<PacientesEspecie> porEspecie;

  const Tablero({
    required this.programadas,
    required this.realizadas,
    required this.canceladas,
    required this.atrasadas,
    required this.porcentajeCumplimiento,
    required this.porTecnico,
    required this.porEspecie,
  });

  factory Tablero.fromJson(Map<String, dynamic> j) {
    final r = Map<String, dynamic>.from(j['resumen'] as Map);
    int n(dynamic v) => (v as num? ?? 0).toInt();
    return Tablero(
      programadas: n(r['programadas']),
      realizadas: n(r['realizadas']),
      canceladas: n(r['canceladas']),
      atrasadas: n(r['atrasadas']),
      porcentajeCumplimiento: (r['porcentajeCumplimiento'] as num? ?? 0).toDouble(),
      porTecnico: [
        for (final t in j['porTecnico'] as List? ?? [])
          CumplimientoTecnico(
            nombre: (t['tecnicoNombre'] ?? '-').toString(),
            realizadas: n(t['realizadas']),
            vencidas: n(t['vencidas']),
            porcentaje: (t['porcentajeCumplimiento'] as num? ?? 0).toDouble(),
          ),
      ],
      porEspecie: [
        for (final e in j['porEspecie'] as List? ?? [])
          PacientesEspecie((e['especie'] ?? '-').toString(), n(e['total'])),
      ],
    );
  }
}

class CumplimientoTecnico {
  final String nombre;
  final int realizadas;
  final int vencidas;
  final double porcentaje;
  const CumplimientoTecnico({
    required this.nombre,
    required this.realizadas,
    required this.vencidas,
    required this.porcentaje,
  });
}

class PacientesEspecie {
  final String especie;
  final int total;
  const PacientesEspecie(this.especie, this.total);
}
