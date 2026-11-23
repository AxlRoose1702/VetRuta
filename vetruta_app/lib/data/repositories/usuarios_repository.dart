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

  /// POST /api/usuarios (solo Root). El médico de un técnico lo asigna después el Director.
  Future<Usuario> crear({
    required String email,
    required String password,
    required String nombreCompleto,
    required String rol,
    int? zonaId,
  }) async {
    final r = await _api.dio.post(
      '/api/usuarios',
      data: {'email': email, 'password': password, 'nombreCompleto': nombreCompleto, 'rol': rol, 'zonaId': zonaId},
    );
    return Usuario.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// PATCH /api/usuarios/{id}/activar o /desactivar (solo Root).
  Future<void> cambiarActivo(String id, bool activo) async {
    await _api.dio.patch('/api/usuarios/$id/${activo ? 'activar' : 'desactivar'}');
  }

  /// PUT /api/usuarios/{id}/medico (solo Director): asigna o reasigna el técnico a un médico.
  Future<void> asignarMedico(String tecnicoId, String medicoId) async {
    await _api.dio.put('/api/usuarios/$tecnicoId/medico', data: {'medicoId': medicoId});
  }

  /// DELETE /api/usuarios/{id}/medico (solo Director): deja al técnico sin médico.
  Future<void> quitarMedico(String tecnicoId) async {
    await _api.dio.delete('/api/usuarios/$tecnicoId/medico');
  }

  /// GET /api/zonas
  Future<List<Zona>> zonas() async {
    final r = await _api.dio.get('/api/zonas');
    return (r.data as List).map((e) => Zona.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
