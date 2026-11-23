import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/fechas.dart';
import '../../data/models/catalogos.dart';
import '../../data/models/visita.dart';
import '../../data/repositories/visitas_repository.dart';
import '../../shared/estado_chip.dart';
import '../visitas/detalle_visita_screen.dart';

/// Actividades (2.11): qué visitas se hicieron, cuáles están pendientes y cuáles se atrasaron [p4].
/// La API ya devuelve solo lo que le toca a cada rol (médico: sus técnicos; director: todo).
/// [cargarTecnicos] da la lista para el filtro por técnico, así la reutiliza el Director.
class ActividadesScreen extends StatefulWidget {
  const ActividadesScreen({super.key, required this.titulo, required this.cargarTecnicos});

  final String titulo;
  final Future<List<Usuario>> Function(BuildContext context) cargarTecnicos;

  @override
  State<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  static const _pestanas = [
    EstadoVisita.pendiente,
    EstadoVisita.atrasada,
    EstadoVisita.realizada,
    EstadoVisita.cancelada,
  ];

  late DateTimeRange _rango;
  String? _tecnicoId;
  List<Usuario> _tecnicos = [];
  List<Visita> _visitas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _rango = DateTimeRange(start: DateTime(hoy.year, hoy.month, 1), end: DateTime(hoy.year, hoy.month + 1, 0));
    widget
        .cargarTecnicos(context)
        .then((t) {
          if (mounted) setState(() => _tecnicos = t);
        })
        .catchError((_) {});
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final v = await VisitasRepository(context.read<ApiClient>())
          .listar(desde: _rango.start, hasta: _rango.end, tecnicoId: _tecnicoId);
      if (mounted) setState(() => _visitas = v);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegirRango() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: _rango,
    );
    if (r != null) {
      setState(() => _rango = r);
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _pestanas.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.titulo),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final e in _pestanas) Tab(text: '${e.etiqueta} (${_visitas.where((v) => v.estado == e).length})'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _elegirRango,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        '${Fechas.soloFecha(_rango.start)} a ${Fechas.soloFecha(_rango.end)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _tecnicoId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Técnico',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                        for (final t in _tecnicos) DropdownMenuItem<String?>(value: t.id, child: Text(t.nombre)),
                      ],
                      onChanged: (v) {
                        setState(() => _tecnicoId = v);
                        _cargar();
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_cargando) const LinearProgressIndicator(),
            if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
            Expanded(
              child: TabBarView(
                children: [for (final e in _pestanas) _lista(_visitas.where((v) => v.estado == e).toList())],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista(List<Visita> visitas) {
    if (visitas.isEmpty) return const Center(child: Text('Sin visitas'));
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        itemCount: visitas.length,
        itemBuilder: (context, i) {
          final v = visitas[i];
          return ListTile(
            leading: Icon(Icons.circle, size: 14, color: v.estado.color),
            title: Text('${v.pacienteNombre} (${v.especieNombre}) · ${v.servicioNombre}'),
            subtitle: Text('${Fechas.larga(v.fechaProgramada)}\nTécnico: ${v.tecnicoNombre ?? '-'}'),
            isThreeLine: true,
            trailing: EstadoChip(v.estado),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleVisitaScreen(visitaId: v.id)));
              _cargar();
            },
          );
        },
      ),
    );
  }
}
