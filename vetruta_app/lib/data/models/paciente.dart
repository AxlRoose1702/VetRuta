import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/fechas.dart';
import 'visita.dart';

/// Un paciente (mascota) tal como lo devuelve GET /api/pacientes (PacienteResponse).
class Paciente {
  final int id;
  final String nombre;
  final DateTime? fechaNacimiento;
  final int razaId;
  final String razaNombre;
  final int especieId;
  final String especieNombre;
  final int duenoId;
  final String duenoNombre;
  final String? duenoTelefono;
  final String? tecnicoId;
  final String? tecnicoNombre;
  final String? fotoUrl;
  final double? latitud;
  final double? longitud;

  const Paciente({
    required this.id,
    required this.nombre,
    required this.fechaNacimiento,
    required this.razaId,
    required this.razaNombre,
    required this.especieId,
    required this.especieNombre,
    required this.duenoId,
    required this.duenoNombre,
    required this.duenoTelefono,
    required this.tecnicoId,
    required this.tecnicoNombre,
    required this.fotoUrl,
    required this.latitud,
    required this.longitud,
  });

  factory Paciente.fromJson(Map<String, dynamic> j) => Paciente(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        fechaNacimiento: j['fechaNacimiento'] == null ? null : DateTime.parse(j['fechaNacimiento'] as String),
        razaId: j['razaId'] as int,
        razaNombre: j['razaNombre'] as String,
        especieId: j['especieId'] as int,
        especieNombre: j['especieNombre'] as String,
        duenoId: j['duenoId'] as int,
        duenoNombre: j['duenoNombre'] as String,
        duenoTelefono: j['duenoTelefono'] as String?,
        tecnicoId: j['tecnicoId'] as String?,
        tecnicoNombre: j['tecnicoNombre'] as String?,
        fotoUrl: j['fotoUrl'] as String?,
        latitud: (j['latitud'] as num?)?.toDouble(),
        longitud: (j['longitud'] as num?)?.toDouble(),
      );

  bool get tieneUbicacion => latitud != null && longitud != null;

  /// La API manda la foto como "/fotos/..."; hay que anteponer la URL de la API.
  String? get fotoCompleta => fotoUrl == null ? null : '${AppConfig.apiUrl}$fotoUrl';
}

/// Estado del paciente para el mapa y la lista. La API no lo manda:
/// se calcula cruzando sus visitas (requisitos 2.14 y 2.17).
enum EstadoPaciente {
  atrasado('Tiene visita atrasada', Colors.red),
  pendiente('Visita pendiente', Colors.amber),
  sinVisita('Sin visita programada', Colors.blueGrey),
  alDia('Al día', Colors.green);

  const EstadoPaciente(this.etiqueta, this.color);
  final String etiqueta;
  final Color color;
}

/// Un paciente con sus visitas, para saber su estado y su próxima visita.
class PacienteConVisitas {
  PacienteConVisitas(this.paciente, List<Visita> visitas)
      : visitas = [...visitas]..sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));

  final Paciente paciente;
  final List<Visita> visitas;

  /// Visitas que siguen programadas (pendientes o atrasadas).
  List<Visita> get porHacer => visitas.where((v) => v.sePuedeRegistrar).toList();

  /// La primera visita por hacer (si está atrasada, es esa).
  Visita? get proximaVisita => porHacer.isEmpty ? null : porHacer.first;

  EstadoPaciente get estado {
    if (porHacer.any((v) => v.estado == EstadoVisita.atrasada)) return EstadoPaciente.atrasado;
    if (porHacer.isNotEmpty) return EstadoPaciente.pendiente;
    if (visitas.any((v) => v.estado == EstadoVisita.realizada)) return EstadoPaciente.alDia;
    return EstadoPaciente.sinVisita;
  }

  String get textoProximaVisita {
    final v = proximaVisita;
    if (v == null) return 'Sin visita programada';
    final atrasada = v.estado == EstadoVisita.atrasada ? ' (ATRASADA)' : '';
    return '${Fechas.larga(v.fechaProgramada)} · ${v.servicioNombre}$atrasada';
  }
}
