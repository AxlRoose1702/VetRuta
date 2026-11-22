import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/fechas.dart';
import '../../data/models/paciente.dart';
import '../../data/models/servicio.dart';
import '../../data/repositories/catalogos_repository.dart';
import '../../data/repositories/pacientes_repository.dart';
import '../../data/repositories/visitas_repository.dart';

/// Programar visita (2.10). La usan el Médico y el Técnico [p3, p4].
/// Cada visita tiene paciente, servicio del catálogo y fecha programada [p3].
/// La API solo devuelve los pacientes que le tocan a cada rol.
class ProgramarVisitaScreen extends StatefulWidget {
  const ProgramarVisitaScreen({super.key, this.pacienteInicial});

  /// Si se abre desde un paciente, ya viene elegido.
  final Paciente? pacienteInicial;

  @override
  State<ProgramarVisitaScreen> createState() => _ProgramarVisitaScreenState();
}

class _ProgramarVisitaScreenState extends State<ProgramarVisitaScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Paciente> _pacientes = [];
  List<Servicio> _servicios = [];
  int? _pacienteId;
  int? _servicioId;
  DateTime? _fecha;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pacienteId = widget.pacienteInicial?.id;
    _cargarListas();
  }

  Future<void> _cargarListas() async {
    final api = context.read<ApiClient>();
    try {
      final resultados = await Future.wait([
        PacientesRepository(api).listar(),
        CatalogosRepository(api).servicios(),
      ]);
      if (!mounted) return;
      setState(() {
        // Solo pacientes con técnico: la API no deja programar si no tiene.
        _pacientes = (resultados[0] as List<Paciente>).where((p) => p.tecnicoId != null).toList();
        _servicios = resultados[1] as List<Servicio>;
        if (_pacientes.every((p) => p.id != _pacienteId)) _pacienteId = null;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.mensajeDeError(e);
          _cargando = false;
        });
      }
    }
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final dia = await showDatePicker(
      context: context,
      initialDate: _fecha ?? ahora,
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: ahora.add(const Duration(days: 365)),
    );
    if (dia == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: _fecha != null ? TimeOfDay.fromDateTime(_fecha!) : const TimeOfDay(hour: 9, minute: 0),
    );
    if (hora == null) return;
    setState(() => _fecha = DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute));
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fecha == null) {
      _aviso('Elige la fecha y la hora.');
      return;
    }
    if (_fecha!.isBefore(DateTime.now())) {
      _aviso('No se puede programar en una fecha pasada.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await VisitasRepository(context.read<ApiClient>()).programar(
        pacienteId: _pacienteId!,
        servicioId: _servicioId!,
        fechaProgramada: _fecha!,
      );
      if (!mounted) return;
      _aviso('Visita programada.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _aviso(ApiClient.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programar visita')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_pacientes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text('No hay pacientes con técnico asignado para programar.'),
                        ),
                      DropdownButtonFormField<int>(
                        initialValue: _pacienteId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Paciente', border: OutlineInputBorder()),
                        items: [
                          for (final p in _pacientes)
                            DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.nombre} (${p.especieNombre}) · ${p.duenoNombre}',
                                  overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) => setState(() => _pacienteId = v),
                        validator: (v) => v == null ? 'Elige el paciente' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _servicioId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Servicio', border: OutlineInputBorder()),
                        items: [
                          for (final s in _servicios)
                            DropdownMenuItem(
                              value: s.id,
                              child: Text(s.descripcion, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) => setState(() => _servicioId = v),
                        validator: (v) => v == null ? 'Elige el servicio' : null,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_month),
                          title: const Text('Fecha y hora'),
                          subtitle: Text(_fecha == null ? 'Toca para elegir' : Fechas.larga(_fecha!)),
                          trailing: const Icon(Icons.edit),
                          onTap: _elegirFecha,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _guardando
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Programar'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
