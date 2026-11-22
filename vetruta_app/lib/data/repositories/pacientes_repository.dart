import '../../core/api_client.dart';
import '../models/paciente.dart';

/// Llamadas a /api/pacientes. La API ya filtra por jerarquía:
/// el técnico recibe solo sus pacientes y el médico los de sus técnicos.
class PacientesRepository {
  PacientesRepository(this._api);
  final ApiClient _api;

  Future<List<Paciente>> listar({String? buscar, int? especieId, String? tecnicoId}) async {
    final r = await _api.dio.get('/api/pacientes', queryParameters: {
      if (buscar != null && buscar.isNotEmpty) 'buscar': buscar,
      'especieId': ?especieId,
      'tecnicoId': ?tecnicoId,
    });
    return (r.data as List).map((e) => Paciente.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}