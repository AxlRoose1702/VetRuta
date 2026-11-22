import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/fechas.dart';
import '../models/visita.dart';

/// Datos que llena el técnico al registrar una visita.
class RegistroVisita {
  final double pesoKg;
  final double alturaCm;
  final double temperatura;
  final String condicion;
  final String? observaciones;
  final double latitud;
  final double longitud;
  final String rutaFoto;

  const RegistroVisita({
    required this.pesoKg,
    required this.alturaCm,
    required this.temperatura,
    required this.condicion,
    required this.observaciones,
    required this.latitud,
    required this.longitud,
    required this.rutaFoto,
  });
}

/// Todas las llamadas a /api/visitas.
class VisitasRepository {
  VisitasRepository(this._api);
  final ApiClient _api;

  /// GET /api/visitas. La API ya filtra por jerarquía (el técnico solo ve las suyas).
  Future<List<Visita>> listar({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    bool? atrasadas,
    String? tecnicoId,
    int? pacienteId,
  }) async {
    final r = await _api.dio.get('/api/visitas', queryParameters: {
      if (desde != null) 'desde': Fechas.soloFecha(desde),
      if (hasta != null) 'hasta': Fechas.soloFecha(hasta),
      'estado': ?estado,
      'atrasadas': ?atrasadas,
      'tecnicoId': ?tecnicoId,
      'pacienteId': ?pacienteId,
    });
    return (r.data as List).map((e) => Visita.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// POST /api/visitas. La fecha se manda en UTC (termina en "Z").
  Future<Visita> programar({
    required int pacienteId,
    required int servicioId,
    required DateTime fechaProgramada,
  }) async {
    final r = await _api.dio.post('/api/visitas', data: {
      'pacienteId': pacienteId,
      'servicioId': servicioId,
      'fechaProgramada': fechaProgramada.toUtc().toIso8601String(),
    });
    return Visita.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// GET /api/visitas/{id}
  Future<Visita> obtener(int id) async {
    final r = await _api.dio.get('/api/visitas/$id');
    return Visita.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// POST /api/visitas/{id}/registro (multipart/form-data con la foto).
  Future<Visita> registrar(int id, RegistroVisita datos) async {
    final nombreFoto = datos.rutaFoto.split(RegExp(r'[\\/]')).last;
    final form = FormData.fromMap({
      'PesoKg': datos.pesoKg.toString(),
      'AlturaCm': datos.alturaCm.toString(),
      'Temperatura': datos.temperatura.toString(),
      'Condicion': datos.condicion,
      'Observaciones': ?datos.observaciones,
      'Latitud': datos.latitud.toString(),
      'Longitud': datos.longitud.toString(),
      'Foto': await MultipartFile.fromFile(datos.rutaFoto, filename: nombreFoto),
    });
    final r = await _api.dio.post('/api/visitas/$id/registro', data: form);
    return Visita.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}