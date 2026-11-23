import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/fechas.dart';
import '../../data/models/tablero.dart';
import '../../data/repositories/tablero_repository.dart';
import '../auth/auth_provider.dart';

/// Tablero con gráficas (2.6) [p4, p5]: realizadas contra programadas,
/// cumplimiento por técnico y pacientes por especie. Lo ven Director, Médico y Técnico [p3];
/// la API ya filtra: el médico ve lo de sus técnicos y el técnico lo suyo.
class TableroScreen extends StatefulWidget {
  const TableroScreen({super.key});

  @override
  State<TableroScreen> createState() => _TableroScreenState();
}

class _TableroScreenState extends State<TableroScreen> {
  static const _colores = [Colors.teal, Colors.orange, Colors.indigo, Colors.pink, Colors.brown, Colors.cyan];

  late DateTimeRange _rango;
  Tablero? _t;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _rango = DateTimeRange(start: DateTime(hoy.year, hoy.month, 1), end: DateTime(hoy.year, hoy.month + 1, 0));
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final t = await TableroRepository(context.read<ApiClient>()).obtener(_rango.start, _rango.end);
      if (mounted) setState(() => _t = t);
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
    final rol = context.watch<AuthProvider>().sesion?.rol;
    final alcance = switch (rol) {
      Roles.medico => 'Datos de tus técnicos',
      Roles.tecnico => 'Tus datos',
      _ => 'Datos de todo el personal',
    };
    final t = _t;

    return Scaffold(
      appBar: AppBar(title: const Text('Tablero')),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              onPressed: _elegirRango,
              icon: const Icon(Icons.date_range),
              label: Text('${Fechas.soloFecha(_rango.start)} a ${Fechas.soloFecha(_rango.end)}'),
            ),
            Text(alcance, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            if (_cargando) const LinearProgressIndicator(),
            if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
            if (t != null) ...[
              const SizedBox(height: 12),
              _tarjetaResumen(t),
              _seccion('Visitas realizadas contra programadas', _graficaVisitas(t)),
              _seccion('Cumplimiento por técnico', _cumplimientoTecnicos(t)),
              _seccion('Pacientes por especie', _graficaEspecies(t)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, Widget contenido) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            contenido,
          ],
        ),
      ),
    );
  }

  Widget _tarjetaResumen(Tablero t) {
    Widget dato(String etiqueta, String valor, Color color) => Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          Text(etiqueta, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            dato('Cumplimiento', '${t.porcentajeCumplimiento.toStringAsFixed(0)}%', Colors.teal),
            dato('Realizadas', '${t.realizadas}', Colors.green),
            dato('Programadas', '${t.programadas}', Colors.amber.shade800),
            dato('Atrasadas', '${t.atrasadas}', Colors.red),
          ],
        ),
      ),
    );
  }

  /// Barras: realizadas, programadas, atrasadas y canceladas.
  Widget _graficaVisitas(Tablero t) {
    final datos = [
      ('Realizadas', t.realizadas, Colors.green),
      ('Programadas', t.programadas, Colors.amber),
      ('Atrasadas', t.atrasadas, Colors.red),
      ('Canceladas', t.canceladas, Colors.grey),
    ];
    final maximo = datos.map((d) => d.$2).fold<int>(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maximo * 1.2,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) =>
                    Text('${datos[v.toInt()].$2}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(datos[v.toInt()].$1, style: const TextStyle(fontSize: 11)),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < datos.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: datos[i].$2.toDouble(),
                    color: datos[i].$3,
                    width: 28,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Barras horizontales con el porcentaje de cada técnico.
  Widget _cumplimientoTecnicos(Tablero t) {
    if (t.porTecnico.isEmpty) return const Text('Sin datos en este rango.');
    return Column(
      children: [
        for (final tec in t.porTecnico)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(tec.nombre)),
                    Text('${tec.porcentaje.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (tec.porcentaje / 100).clamp(0, 1),
                    minHeight: 14,
                    color: tec.porcentaje >= 80 ? Colors.green : (tec.porcentaje >= 50 ? Colors.amber : Colors.red),
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
                Text(
                  '${tec.realizadas} realizada(s) · ${tec.vencidas} vencida(s)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Dona: pacientes por especie.
  Widget _graficaEspecies(Tablero t) {
    final total = t.porEspecie.fold<int>(0, (a, e) => a + e.total);
    if (total == 0) return const Text('Sin pacientes.');
    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 30,
              sectionsSpace: 2,
              sections: [
                for (var i = 0; i < t.porEspecie.length; i++)
                  PieChartSectionData(
                    value: t.porEspecie[i].total.toDouble(),
                    color: _colores[i % _colores.length],
                    title: '${t.porEspecie[i].total}',
                    radius: 40,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < t.porEspecie.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 12, color: _colores[i % _colores.length]),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${t.porEspecie[i].especie}: ${t.porEspecie[i].total}')),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
