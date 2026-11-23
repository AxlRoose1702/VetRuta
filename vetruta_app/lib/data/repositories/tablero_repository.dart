import '../../core/api_client.dart';
import '../../core/fechas.dart';
import '../models/tablero.dart';

/// GET /api/tablero?desde=&hasta= (Director, Médico y Técnico; la API filtra por jerarquía).
class TableroRepository {
  TableroRepository(this._api);
  final ApiClient _api;

  Future<Tablero> obtener(DateTime desde, DateTime hasta) async {
    final r = await _api.dio.get(
      '/api/tablero',
      queryParameters: {'desde': Fechas.soloFecha(desde), 'hasta': Fechas.soloFecha(hasta)},
    );
    return Tablero.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
