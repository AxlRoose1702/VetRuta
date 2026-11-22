/// Configuración general de la app.
class AppConfig {
  /// URL de la API. Desde el emulador de Android, 10.0.2.2 es "localhost" de tu PC.
  /// Cambia el puerto por el del perfil "http" de launchSettings.json.
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5053',
  );
}

/// Nombres de los roles tal como los manda la API en el login.
class Roles {
  static const String root = 'Root';
  static const String director = 'Director';
  static const String medico = 'Medico';
  static const String tecnico = 'Tecnico';

  /// Nombre bonito para mostrar en pantalla.
  static String etiqueta(String rol) {
    switch (rol) {
      case medico:
        return 'Médico';
      case tecnico:
        return 'Técnico';
      default:
        return rol;
    }
  }
}