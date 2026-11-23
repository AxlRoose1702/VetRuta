import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/api_client.dart';
import '../../core/fechas.dart';
import '../../data/models/visita.dart';
import '../../data/repositories/visitas_repository.dart';
import '../../shared/estado_chip.dart';
import '../visitas/detalle_visita_screen.dart';
import 'calendario_provider.dart';

/// Calendario de visitas del técnico con su estado: pendiente, realizada o atrasada [p4, p5].
class CalendarioScreen extends StatelessWidget {
  const CalendarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CalendarioProvider(VisitasRepository(ctx.read<ApiClient>())),
      child: const _CalendarioVista(),
    );
  }
}

class _CalendarioVista extends StatelessWidget {
  const _CalendarioVista();

  Future<void> _abrirVisita(BuildContext context, Visita v) async {
    final cal = context.read<CalendarioProvider>();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleVisitaScreen(visitaId: v.id)));
    // Al regresar se recarga, por si se registró la visita.
    cal.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final cal = context.watch<CalendarioProvider>();
    final visitasDia = cal.visitasDelDia(cal.diaSeleccionado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de visitas'),
        actions: [IconButton(icon: const Icon(Icons.refresh), tooltip: 'Recargar', onPressed: cal.recargar)],
      ),
      body: Column(
        children: [
          TableCalendar<Visita>(
            locale: 'es',
            firstDay: DateTime(2024, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: cal.mesVisible,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
            headerStyle: const HeaderStyle(titleCentered: true),
            selectedDayPredicate: (dia) => isSameDay(dia, cal.diaSeleccionado),
            eventLoader: cal.visitasDelDia,
            onDaySelected: (dia, _) => cal.seleccionarDia(dia),
            onPageChanged: cal.cargarMes,
            calendarBuilders: CalendarBuilders(
              // Un punto de color por visita, según su estado.
              markerBuilder: (context, dia, visitas) {
                if (visitas.isEmpty) return null;
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final v in visitas.take(4))
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(color: v.estado.color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: LeyendaEstados()),
          if (cal.cargando) const LinearProgressIndicator(),
          if (cal.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(cal.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(Fechas.dia(cal.diaSeleccionado), style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          Expanded(
            child: visitasDia.isEmpty
                ? const Center(child: Text('No hay visitas este día'))
                : ListView.builder(
                    itemCount: visitasDia.length,
                    itemBuilder: (context, i) {
                      final v = visitasDia[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: v.estado.color.withValues(alpha: 0.2),
                          child: Icon(Icons.pets, color: v.estado.color),
                        ),
                        title: Text('${v.pacienteNombre} (${v.especieNombre})'),
                        subtitle: Text(
                          '${Fechas.hora(v.fechaProgramada)} · ${v.servicioNombre}\nDueño: ${v.duenoNombre}',
                        ),
                        isThreeLine: true,
                        trailing: EstadoChip(v.estado),
                        onTap: () => _abrirVisita(context, v),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
