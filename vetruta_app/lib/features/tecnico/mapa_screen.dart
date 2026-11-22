import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../data/models/paciente.dart';
import '../../data/repositories/pacientes_repository.dart';
import '../../data/repositories/visitas_repository.dart';
import '../pacientes/paciente_resumen_sheet.dart';
import 'pacientes_tecnico_provider.dart';

/// Mapa de Google Maps con un marcador por paciente, del color de su estado [p4, p5].
class MapaScreen extends StatelessWidget {
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final api = ctx.read<ApiClient>();
        return PacientesTecnicoProvider(PacientesRepository(api), VisitasRepository(api));
      },
      child: const _MapaVista(),
    );
  }
}

class _MapaVista extends StatefulWidget {
  const _MapaVista();

  @override
  State<_MapaVista> createState() => _MapaVistaState();
}

class _MapaVistaState extends State<_MapaVista> {
  static const LatLng _ciudadDeGuatemala = LatLng(14.6349, -90.5069);
  final Completer<GoogleMapController> _mapa = Completer();
  int _marcadoresEncuadrados = -1;

  /// Color del marcador según el estado del paciente.
  double _tono(EstadoPaciente estado) {
    switch (estado) {
      case EstadoPaciente.atrasado:
        return BitmapDescriptor.hueRed;
      case EstadoPaciente.pendiente:
        return BitmapDescriptor.hueYellow;
      case EstadoPaciente.alDia:
        return BitmapDescriptor.hueGreen;
      case EstadoPaciente.sinVisita:
        return BitmapDescriptor.hueAzure;
    }
  }

  Future<void> _abrir(PacienteConVisitas item) async {
    final prov = context.read<PacientesTecnicoProvider>();
    final cambio = await mostrarResumenPaciente(context, item);
    if (cambio == true) prov.cargar();
  }

  /// Mueve la cámara para que se vean todos los marcadores.
  Future<void> _encuadrar(List<PacienteConVisitas> items) async {
    if (items.isEmpty || _marcadoresEncuadrados == items.length) return;
    _marcadoresEncuadrados = items.length;
    final controller = await _mapa.future;
    if (items.length == 1) {
      final p = items.first.paciente;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.latitud!, p.longitud!), 15));
      return;
    }
    final lats = items.map((i) => i.paciente.latitud!);
    final lngs = items.map((i) => i.paciente.longitud!);
    final limites = LatLngBounds(
      southwest: LatLng(lats.reduce((a, b) => a < b ? a : b), lngs.reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(lats.reduce((a, b) => a > b ? a : b), lngs.reduce((a, b) => a > b ? a : b)),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(limites, 60));
  }

  void _verSinUbicacion(List<PacienteConVisitas> items) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Estos pacientes aún no tienen ubicación. Se guarda sola al registrar su primera visita.',
              ),
            ),
            for (final i in items)
              ListTile(
                leading: Icon(Icons.location_off, color: i.estado.color),
                title: Text(i.paciente.nombre),
                subtitle: Text('${i.paciente.duenoNombre} · ${i.textoProximaVisita}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _abrir(i);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PacientesTecnicoProvider>();
    final conUbicacion = prov.conUbicacion;
    final sinUbicacion = prov.sinUbicacion;
    WidgetsBinding.instance.addPostFrameCallback((_) => _encuadrar(conUbicacion));

    final marcadores = {
      for (final item in conUbicacion)
        Marker(
          markerId: MarkerId('paciente-${item.paciente.id}'),
          position: LatLng(item.paciente.latitud!, item.paciente.longitud!),
          icon: BitmapDescriptor.defaultMarkerWithHue(_tono(item.estado)),
          infoWindow: InfoWindow(
            title: item.paciente.nombre,
            snippet: '${item.estado.etiqueta} · toca aquí para ver más',
            onTap: () => _abrir(item),
          ),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de pacientes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Recargar', onPressed: prov.cargar),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _ciudadDeGuatemala, zoom: 12),
            markers: marcadores,
            myLocationButtonEnabled: false,
            onMapCreated: (c) {
              if (!_mapa.isCompleted) _mapa.complete(c);
            },
          ),
          if (prov.cargando) const LinearProgressIndicator(),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 12, runSpacing: 4, children: [
                      for (final e in EstadoPaciente.values)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.location_on, size: 16, color: e == EstadoPaciente.sinVisita ? Colors.lightBlue : e.color),
                          Text(e.etiqueta, style: const TextStyle(fontSize: 12)),
                        ]),
                    ]),
                    if (prov.error != null)
                      Text(prov.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    if (sinUbicacion.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.location_off),
                        label: Text('${sinUbicacion.length} paciente(s) sin ubicación'),
                        onPressed: () => _verSinUbicacion(sinUbicacion),
                      ),
                    if (!prov.cargando && prov.error == null && prov.pacientes.isEmpty)
                      const Text('No tienes pacientes asignados.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}