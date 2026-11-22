import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../data/models/visita.dart';
import '../../data/repositories/visitas_repository.dart';

/// Estado del calendario: el mes que se ve, el día elegido y las visitas del mes.
class CalendarioProvider extends ChangeNotifier {
  CalendarioProvider(this._repo) {
    cargarMes(mesVisible);
  }

  final VisitasRepository _repo;

  DateTime mesVisible = DateTime.now();
  DateTime diaSeleccionado = DateTime.now();
  bool cargando = false;
  String? error;

  /// Visitas agrupadas por día (sin hora) para pintar el calendario.
  final Map<DateTime, List<Visita>> _porDia = {};

  static DateTime _soloDia(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Visita> visitasDelDia(DateTime dia) => _porDia[_soloDia(dia)] ?? const [];

  Future<void> cargarMes(DateTime mes) async {
    mesVisible = mes;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      // Un día de margen por la diferencia entre UTC y la hora local.
      final desde = DateTime(mes.year, mes.month, 1).subtract(const Duration(days: 1));
      final hasta = DateTime(mes.year, mes.month + 1, 0).add(const Duration(days: 1));
      final visitas = await _repo.listar(desde: desde, hasta: hasta);
      _porDia.clear();
      for (final v in visitas) {
        _porDia.putIfAbsent(_soloDia(v.fechaProgramada), () => []).add(v);
      }
    } catch (e) {
      error = ApiClient.mensajeDeError(e);
    }
    cargando = false;
    notifyListeners();
  }

  void seleccionarDia(DateTime dia) {
    diaSeleccionado = dia;
    notifyListeners();
  }

  Future<void> recargar() => cargarMes(mesVisible);
}