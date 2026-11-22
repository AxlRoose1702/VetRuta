import 'package:dio/dio.dart';

import 'config.dart';

/// Cliente HTTP único de la app.
/// - Agrega el encabezado `Authorization: Bearer <token>` a cada petición.
/// - Si la API responde 401 con sesión abierta, avisa para cerrar la sesión.
class ApiClient {
  ApiClient()
      : dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = token;
        if (t != null) options.headers['Authorization'] = 'Bearer $t';
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401 && token != null) {
          onNoAutorizado?.call();
        }
        handler.next(error);
      },
    ));
  }

  final Dio dio;

  /// Token JWT de la sesión actual (null si no hay sesión).
  String? token;

  /// Se llama cuando la API responde 401 (token vencido o usuario desactivado).
  void Function()? onNoAutorizado;

  /// Convierte cualquier error en un texto para mostrar al usuario.
  /// La API manda los errores como { "mensaje": "..." }.
  static String mensajeDeError(Object error, {String? en401}) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'No se pudo conectar con la API (${AppConfig.apiUrl}). '
            'Revisa que esté corriendo con el perfil http.';
      }
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map) {
        if (data['mensaje'] != null) return data['mensaje'].toString();
        if (data['errores'] is List) return (data['errores'] as List).join('\n');
        if (data['errors'] is Map) {
          return (data['errors'] as Map)
              .values
              .expand((v) => v is List ? v : [v])
              .join('\n');
        }
      }
      switch (status) {
        case 401:
          return en401 ?? 'Tu sesión no es válida. Ingresa de nuevo.';
        case 403:
          return 'Tu rol no tiene permiso para esta acción.';
        case 404:
          return 'No se encontró el registro.';
        case 409:
          return 'Conflicto: el registro ya existe o está en uso.';
      }
      return 'Error de la API (${status ?? error.type.name}).';
    }
    return error.toString();
  }
}