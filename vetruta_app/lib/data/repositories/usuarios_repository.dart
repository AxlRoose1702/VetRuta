import '../../core/api_client.dart';
import '../models/catalogos.dart';

/// Llamadas a /api/usuarios.
class UsuariosRepository {
  UsuariosRepository(this._api);
  final ApiClient _api;

  List<Usuario> _usuarios(dynamic data) =>
      (data as List).map((e) => Usuario.fromJson(Map<String, dynamic>.from(e as Map))).toList();

  /// GET /api/usuarios/medicos/{medicoId}/tecnicos (un médico solo puede pedir los suyos).
  Future<List<Usuario>> tecnicosDeMedico(String medicoId) async {
    final r = await _api.dio.get('/api/usuarios/medicos/$medicoId/tecnicos');
    return _usuarios(r.data);
  }

  /// GET /api/usuarios?rol=&activo= (Root y Director).
  Future<List<Usuario>> listar({String? rol, bool? activo}) async {
    final r = await _api.dio.get('/api/usuarios', queryParameters: {'rol': ?rol, 'activo': ?activo});
    return _usuarios(r.data);
  }
}
