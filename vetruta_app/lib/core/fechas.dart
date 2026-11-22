import 'package:intl/intl.dart';

/// Ayudas para fechas. La API guarda y compara en UTC; la app muestra en hora local.
class Fechas {
  /// Lee una fecha de la API como UTC aunque venga sin "Z" al final.
  static DateTime? leerUtc(dynamic valor) {
    if (valor == null) return null;
    var texto = valor.toString();
    final tieneZona = texto.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(texto);
    if (!tieneZona) texto = '${texto}Z';
    return DateTime.parse(texto).toLocal();
  }

  /// Fecha para mandar en la URL: 2026-11-22
  static String soloFecha(DateTime fecha) => DateFormat('yyyy-MM-dd').format(fecha);

  static String hora(DateTime fecha) => DateFormat('HH:mm').format(fecha);

  static String larga(DateTime fecha) => DateFormat("d 'de' MMMM yyyy, HH:mm", 'es').format(fecha);

  static String dia(DateTime fecha) => DateFormat("EEEE d 'de' MMMM", 'es').format(fecha);
}