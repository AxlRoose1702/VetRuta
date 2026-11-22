import '../../core/api_client.dart';
import '../models/catalogos.dart';
import '../models/servicio.dart';

/// Catálogos de la API: servicios, especies, razas y dueños.
class CatalogosRepository {
  CatalogosRepository(this._api);
  final ApiClient _api;

  List<Map<String, dynamic>> _lista(dynamic data) =>
      (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<List<Servicio>> servicios() async {
    final r = await _api.dio.get('/api/servicios');
    return _lista(r.data).map(Servicio.fromJson).toList();
  }

  Future<List<Especie>> especies() async {
    final r = await _api.dio.get('/api/especies');
    return _lista(r.data).map(Especie.fromJson).toList();
  }

  Future<List<Raza>> razasDeEspecie(int especieId) async {
    final r = await _api.dio.get('/api/especies/$especieId/razas');
    return _lista(r.data).map(Raza.fromJson).toList();
  }

  /// GET /api/duenos?buscar= (busca por nombre o teléfono)
  Future<List<Dueno>> buscarDuenos(String texto) async {
    final r = await _api.dio.get('/api/duenos', queryParameters: {if (texto.isNotEmpty) 'buscar': texto});
    return _lista(r.data).map(Dueno.fromJson).toList();
  }

  Future<Dueno> crearDueno({required String nombre, String? telefono, String? direccion}) async {
    final r = await _api.dio.post('/api/duenos', data: {
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
    });
    return Dueno.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
