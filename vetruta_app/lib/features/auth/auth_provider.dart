import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api_client.dart';
import '../../core/navegacion.dart';
import '../../core/sesion.dart';

enum EstadoAuth { cargando, sinSesion, conSesion }

/// Estado de la sesión (gestor de estado: provider + ChangeNotifier).
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api) {
    _api.onNoAutorizado = () {
      if (estado == EstadoAuth.conSesion) {
        cerrarSesion(aviso: 'Tu sesión venció o tu usuario fue desactivado. Ingresa de nuevo.');
      }
    };
  }

  final ApiClient _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _clave = 'sesion';

  EstadoAuth estado = EstadoAuth.cargando;
  Sesion? sesion;

  /// Mensaje que muestra el login (por ejemplo, "tu sesión venció").
  String? aviso;

  /// Al abrir la app: si hay un token guardado y sigue válido, entra directo.
  Future<void> restaurarSesion() async {
    try {
      final guardada = await _storage.read(key: _clave);
      if (guardada != null) {
        final s = Sesion.fromJson(jsonDecode(guardada) as Map<String, dynamic>);
        if (!s.vencida) {
          _api.token = s.token;
          await _api.dio.get('/api/auth/me'); // confirma que el token y el usuario siguen activos
          sesion = s;
          estado = EstadoAuth.conSesion;
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // Token inválido, usuario desactivado o API apagada: se pide login.
    }
    _api.token = null;
    await _storage.delete(key: _clave);
    estado = EstadoAuth.sinSesion;
    notifyListeners();
  }

  /// POST /api/auth/login. Si falla, lanza el error para que la pantalla lo muestre.
  Future<void> login(String email, String password) async {
    final respuesta = await _api.dio.post('/api/auth/login', data: {'email': email.trim(), 'password': password});
    final s = Sesion.fromJson(Map<String, dynamic>.from(respuesta.data as Map));
    _api.token = s.token;
    await _storage.write(key: _clave, value: jsonEncode(s.toJson()));
    sesion = s;
    aviso = null;
    estado = EstadoAuth.conSesion;
    notifyListeners();
  }

  Future<void> cerrarSesion({String? aviso}) async {
    _api.token = null;
    sesion = null;
    this.aviso = aviso;
    estado = EstadoAuth.sinSesion;
    // Cierra las pantallas abiertas para volver al login.
    navigatorKey.currentState?.popUntil((ruta) => ruta.isFirst);
    notifyListeners();
    await _storage.delete(key: _clave);
  }
}
