import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/fechas.dart';
import '../../data/models/visita.dart';
import '../../data/repositories/visitas_repository.dart';
import '../../shared/estado_chip.dart';
import '../auth/auth_provider.dart';
import 'registrar_visita_screen.dart';

/// Detalle de una visita. Una visita realizada es de solo lectura [p4]:
/// no hay botones para editar ni borrar.
class DetalleVisitaScreen extends StatefulWidget {
  const DetalleVisitaScreen({super.key, required this.visitaId});

  final int visitaId;

  @override
  State<DetalleVisitaScreen> createState() => _DetalleVisitaScreenState();
}

class _DetalleVisitaScreenState extends State<DetalleVisitaScreen> {
  Visita? _visita;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final v = await VisitasRepository(context.read<ApiClient>()).obtener(widget.visitaId);
      if (mounted) setState(() => _visita = v);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.mensajeDeError(e));
    }
  }

  Future<void> _registrar() async {
    final registrada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RegistrarVisitaScreen(visita: _visita!)),
    );
    if (registrada == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final rol = context.watch<AuthProvider>().sesion?.rol;
    final v = _visita;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de visita')),
      body: _error != null
          ? Center(
              child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)),
            )
          : v == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(v.pacienteNombre, style: Theme.of(context).textTheme.headlineSmall)),
                      EstadoChip(v.estado),
                    ],
                  ),
                  Text('${v.especieNombre} · Dueño: ${v.duenoNombre}'),
                  const SizedBox(height: 16),
                  _Dato('Servicio', v.servicioNombre),
                  _Dato('Fecha programada', Fechas.larga(v.fechaProgramada)),
                  _Dato('Técnico', v.tecnicoNombre ?? '-'),
                  if (v.estado == EstadoVisita.realizada) ...[
                    const Divider(height: 32),
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: const ListTile(
                        leading: Icon(Icons.lock_outline),
                        title: Text('Visita registrada'),
                        subtitle: Text('Información histórica de solo lectura.'),
                      ),
                    ),
                    _Dato('Registrada el', v.fechaRegistro == null ? '-' : Fechas.larga(v.fechaRegistro!)),
                    _Dato('Peso', '${v.pesoKg} kg'),
                    _Dato('Altura', '${v.alturaCm} cm'),
                    _Dato('Temperatura', '${v.temperatura} °C'),
                    _Dato('Condición corporal', v.condicion ?? '-'),
                    _Dato('Observaciones', v.observaciones ?? '-'),
                    _Dato('Ubicación', '${v.latitud}, ${v.longitud}'),
                    const SizedBox(height: 8),
                    if (v.fotoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          '${AppConfig.apiUrl}${v.fotoUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Text('No se pudo cargar la foto'),
                        ),
                      ),
                  ],
                  if (v.estado == EstadoVisita.cancelada)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Esta visita fue cancelada por el médico.'),
                    ),
                  if (v.sePuedeRegistrar && rol == Roles.tecnico) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _registrar,
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text('Registrar visita'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}
