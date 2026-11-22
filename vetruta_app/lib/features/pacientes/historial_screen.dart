import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/fechas.dart';
import '../../data/models/visita.dart';
import '../../data/repositories/pacientes_repository.dart';
import '../../shared/estado_chip.dart';
import '../../shared/paciente_avatar.dart';
import '../visitas/detalle_visita_screen.dart';

/// Historial del paciente (2.12). Cada visita queda guardada y no se sobrescribe,
/// para ver la evolución, por ejemplo del peso [p3].
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key, required this.pacienteId});

  final int pacienteId;

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  HistorialPaciente? _h;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final h = await PacientesRepository(context.read<ApiClient>()).historial(widget.pacienteId);
      if (mounted) setState(() => _h = h);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.mensajeDeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _h;
    return Scaffold(
      appBar: AppBar(title: const Text('Historial del paciente')),
      body: _error != null
          ? Center(child: Text(_error!))
          : h == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: PacienteAvatar(h.paciente, radio: 32),
                        title: Text(h.paciente.nombre, style: Theme.of(context).textTheme.titleLarge),
                        subtitle: Text('${h.paciente.especieNombre} · ${h.paciente.razaNombre}'
                            '${h.paciente.fechaNacimiento != null ? '\nNació aprox.: ${Fechas.soloFecha(h.paciente.fechaNacimiento!)}' : ''}'),
                      ),
                      Text('Dueño: ${h.paciente.duenoNombre} · Tel: ${h.paciente.duenoTelefono ?? '-'}'),
                      Text('Técnico: ${h.paciente.tecnicoNombre ?? '-'}'),
                      const SizedBox(height: 8),
                      Text('${h.visitas.length} visita(s) · ${h.realizadas.length} realizada(s)',
                          style: Theme.of(context).textTheme.titleSmall),
                      if (h.realizadas.where((v) => v.pesoKg != null).length >= 2) ...[
                        const SizedBox(height: 16),
                        Text('Evolución del peso (kg)', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        SizedBox(height: 180, child: _GraficaPeso(h.realizadas)),
                      ],
                      const Divider(height: 32),
                      if (h.visitas.isEmpty) const Text('Aún no tiene visitas.'),
                      for (final v in h.visitas) _TarjetaVisita(v),
                    ],
                  ),
                ),
    );
  }
}

/// Gráfica de línea del peso en el tiempo.
class _GraficaPeso extends StatelessWidget {
  const _GraficaPeso(this.realizadas);

  final List<Visita> realizadas;

  @override
  Widget build(BuildContext context) {
    final conPeso = realizadas.where((v) => v.pesoKg != null && v.fechaRegistro != null).toList()
      ..sort((a, b) => a.fechaRegistro!.compareTo(b.fechaRegistro!));
    final puntos = [for (var i = 0; i < conPeso.length; i++) FlSpot(i.toDouble(), conPeso[i].pesoKg!)];
    final color = Theme.of(context).colorScheme.primary;

    return LineChart(LineChartData(
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (valor, meta) {
              final i = valor.toInt();
              if (i < 0 || i >= conPeso.length) return const SizedBox.shrink();
              final f = conPeso[i].fechaRegistro!;
              return Text('${f.day}/${f.month}', style: const TextStyle(fontSize: 10));
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(spots: puntos, color: color, barWidth: 3, dotData: const FlDotData(show: true)),
      ],
    ));
  }
}

class _TarjetaVisita extends StatelessWidget {
  const _TarjetaVisita(this.v);

  final Visita v;

  @override
  Widget build(BuildContext context) {
    final realizada = v.estado == EstadoVisita.realizada;
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetalleVisitaScreen(visitaId: v.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(v.servicioNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              EstadoChip(v.estado),
            ]),
            Text(realizada && v.fechaRegistro != null
                ? 'Registrada: ${Fechas.larga(v.fechaRegistro!)}'
                : 'Programada: ${Fechas.larga(v.fechaProgramada)}'),
            Text('Técnico: ${v.tecnicoNombre ?? '-'}'),
            if (realizada) ...[
              const SizedBox(height: 4),
              Text('Peso ${v.pesoKg} kg · Altura ${v.alturaCm} cm · Temp. ${v.temperatura} °C'),
              Text('Condición corporal: ${v.condicion ?? '-'}'),
              if (v.observaciones != null) Text('Observaciones: ${v.observaciones}'),
              if (v.fotoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      '${AppConfig.apiUrl}${v.fotoUrl}',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Text('No se pudo cargar la foto'),
                    ),
                  ),
                ),
            ],
          ]),
        ),
      ),
    );
  }
}
