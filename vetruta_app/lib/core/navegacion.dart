import 'package:flutter/material.dart';

/// Llave del Navigator de toda la app. Sirve para regresar al inicio
/// cuando la sesión se cierra, aunque haya pantallas abiertas encima.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();