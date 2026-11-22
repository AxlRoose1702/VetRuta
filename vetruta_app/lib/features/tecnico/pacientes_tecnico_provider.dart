import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../data/models/paciente.dart';
import '../../data/models/visita.dart';
import '../../data/repositories/pacientes_repository.dart';
import '../../data/repositories/visitas_repository.dart';

/// Carga los pacientes del técnico y sus visitas, y los cruza por pacienteId.
/// Lo usan el Mapa (2.14) y Mis pacientes (2.17).
class PacientesTecnicoProvider extends ChangeNotifier {
  PacientesTecnicoProvider(this._pacientesRepo, this._visitasRepo) {
    cargar();
  }

  final PacientesRepository _pacientesRepo;
  final VisitasRepository _visitasRepo;

  List<PacienteConVisitas> pacientes = [];
  bool cargando = false;
  String? error;

  List<PacienteConVisitas> get conUbicacion => pacientes.where((p) => p.paciente.tieneUbicacion).toList();
  List<PacienteConVisitas> get sinUbicacion => pacientes.where((p) => !p.paciente.tieneUbicacion).toList();

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      // Las dos llamadas al mismo tiempo.
      final resultados = await Future.wait([_pacientesRepo.listar(), _visitasRepo.listar()]);
      final lista = resultados[0] as List<Paciente>;
      final visitas = resultados[1] as List<Visita>;

      final porPaciente = <int, List<Visita>>{};
      for (final v in visitas) {
        porPaciente.putIfAbsent(v.pacienteId, () => []).add(v);
      }
      pacientes = [for (final p in lista) PacienteConVisitas(p, porPaciente[p.id] ?? [])];
      // Orden: atrasados, pendientes, sin visita y al día.
      pacientes.sort((a, b) => a.estado.index.compareTo(b.estado.index));
    } catch (e) {
      error = ApiClient.mensajeDeError(e);
    }
    cargando = false;
    notifyListeners();
  }
}
