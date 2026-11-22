import 'package:flutter/material.dart';

import '../../core/fechas.dart';

/// Estado que pide el enunciado: pendiente, realizada o atrasada [p5].
/// La API manda "estado" (Programada, Realizada, Cancelada) y "atrasada" (bool).
enum EstadoVisita {
  pendiente('Pendiente', Colors.amber),
  realizada('Realizada', Colors.green),
  atrasada('Atrasada', Colors.red),
  cancelada('Cancelada', Colors.grey);

  const EstadoVisita(this.etiqueta, this.color);
  final String etiqueta;
  final Color color;
}

/// Una visita tal como la devuelve GET /api/visitas (VisitaResponse).
class Visita {
  final int id;
  final int pacienteId;
  final String pacienteNombre;
  final String especieNombre;
  final String duenoNombre;
  final int servicioId;
  final String servicioNombre;
  final String tecnicoId;
  final String? tecnicoNombre;
  final DateTime fechaProgramada; // en hora local
  final String estadoApi; // Programada, Realizada o Cancelada
  final bool atrasadaApi;
  final DateTime? fechaRegistro;
  final double? pesoKg;
  final double? alturaCm;
  final double? temperatura;
  final String? condicion;
  final double? latitud;
  final double? longitud;
  final String? fotoUrl;
  final String? observaciones;

  const Visita({
    required this.id,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.especieNombre,
    required this.duenoNombre,
    required this.servicioId,
    required this.servicioNombre,
    required this.tecnicoId,
    required this.tecnicoNombre,
    required this.fechaProgramada,
    required this.estadoApi,
    required this.atrasadaApi,
    required this.fechaRegistro,
    required this.pesoKg,
    required this.alturaCm,
    required this.temperatura,
    required this.condicion,
    required this.latitud,
    required this.longitud,
    required this.fotoUrl,
    required this.observaciones,
  });

  factory Visita.fromJson(Map<String, dynamic> j) => Visita(
        id: j['id'] as int,
        pacienteId: j['pacienteId'] as int,
        pacienteNombre: j['pacienteNombre'] as String,
        especieNombre: j['especieNombre'] as String,
        duenoNombre: j['duenoNombre'] as String,
        servicioId: j['servicioId'] as int,
        servicioNombre: j['servicioNombre'] as String,
        tecnicoId: j['tecnicoId'] as String,
        tecnicoNombre: j['tecnicoNombre'] as String?,
        fechaProgramada: Fechas.leerUtc(j['fechaProgramada'])!,
        estadoApi: j['estado'].toString(),
        atrasadaApi: j['atrasada'] as bool? ?? false,
        fechaRegistro: Fechas.leerUtc(j['fechaRegistro']),
        pesoKg: (j['pesoKg'] as num?)?.toDouble(),
        alturaCm: (j['alturaCm'] as num?)?.toDouble(),
        temperatura: (j['temperatura'] as num?)?.toDouble(),
        condicion: j['condicion'] as String?,
        latitud: (j['latitud'] as num?)?.toDouble(),
        longitud: (j['longitud'] as num?)?.toDouble(),
        fotoUrl: j['fotoUrl'] as String?,
        observaciones: j['observaciones'] as String?,
      );

  /// Traduce el estado de la API al estado que pide el enunciado.
  EstadoVisita get estado {
    if (estadoApi == 'Realizada') return EstadoVisita.realizada;
    if (estadoApi == 'Cancelada') return EstadoVisita.cancelada;
    return atrasadaApi ? EstadoVisita.atrasada : EstadoVisita.pendiente;
  }

  /// Solo se registra una visita que sigue programada (pendiente o atrasada).
  bool get sePuedeRegistrar => estadoApi == 'Programada';
}