import '../../core/api_client.dart';
import '../models/servicio.dart';

/// Catálogos de la API (servicios; luego especies y razas).
class CatalogosRepository {
  CatalogosRepository(this._api);
  final ApiClient _api;

  Future<List<Servicio>> servicios() async {
    final r = await _api.dio.get('/api/servicios');
    return (r.data as List).map((e) => Servicio.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}