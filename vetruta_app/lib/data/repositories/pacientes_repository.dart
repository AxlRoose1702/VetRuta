import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/fechas.dart';
import '../models/paciente.dart';
import '../models/visita.dart';

/// Historial de un paciente: sus datos y todas sus visitas (más reciente primero).
class HistorialPaciente {
  HistorialPaciente(this.paciente, this.visitas);
  final Paciente paciente;
  final List<Visita> visitas;

  List<Visita> get realizadas => visitas.where((v) => v.estado == EstadoVisita.realizada).toList();
}

/// Llamadas a /api/pacientes. La API ya filtra por jerarquía:
/// el técnico recibe solo sus pacientes y el médico los de sus técnicos.
class PacientesRepository {
  PacientesRepository(this._api);
  final ApiClient _api;

  Paciente _paciente(dynamic data) => Paciente.fromJson(Map<String, dynamic>.from(data as Map));

  Future<List<Paciente>> listar({String? buscar, int? especieId, String? tecnicoId}) async {
    final r = await _api.dio.get(
      '/api/pacientes',
      queryParameters: {
        if (buscar != null && buscar.isNotEmpty) 'buscar': buscar,
        'especieId': ?especieId,
        'tecnicoId': ?tecnicoId,
      },
    );
    return (r.data as List).map(_paciente).toList();
  }

  /// POST /api/pacientes (solo Médico).
  Future<Paciente> crear({
    required String nombre,
    DateTime? fechaNacimiento,
    required int razaId,
    required int duenoId,
    required String tecnicoId,
    double? latitud,
    double? longitud,
  }) async {
    final r = await _api.dio.post(
      '/api/pacientes',
      data: {
        'nombre': nombre,
        'fechaNacimiento': fechaNacimiento == null ? null : Fechas.soloFecha(fechaNacimiento),
        'razaId': razaId,
        'duenoId': duenoId,
        'tecnicoId': tecnicoId,
        'latitud': latitud,
        'longitud': longitud,
      },
    );
    return _paciente(r.data);
  }

  /// POST /api/pacientes/{id}/foto (multipart, campo "foto"; JPG o PNG, máx. 5 MB).
  Future<void> subirFoto(int pacienteId, String rutaFoto) async {
    final nombre = rutaFoto.split(RegExp(r'[\\/]')).last;
    final form = FormData.fromMap({'foto': await MultipartFile.fromFile(rutaFoto, filename: nombre)});
    await _api.dio.post('/api/pacientes/$pacienteId/foto', data: form);
  }

  /// PUT /api/pacientes/{id}/tecnico (solo Médico, a uno de sus técnicos).
  Future<void> cambiarTecnico(int pacienteId, String tecnicoId) async {
    await _api.dio.put('/api/pacientes/$pacienteId/tecnico', data: {'tecnicoId': tecnicoId});
  }

  /// GET /api/pacientes/{id}/historial
  Future<HistorialPaciente> historial(int pacienteId) async {
    final r = await _api.dio.get('/api/pacientes/$pacienteId/historial');
    final data = Map<String, dynamic>.from(r.data as Map);
    // Busca el objeto del paciente y la lista de visitas, sin depender del nombre exacto del campo.
    final paciente = data.values.firstWhere((v) => v is Map);
    final visitas = data.values.firstWhere((v) => v is List) as List;
    return HistorialPaciente(
      _paciente(paciente),
      visitas.map((e) => Visita.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}
