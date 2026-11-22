import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../data/models/paciente.dart';
import '../../shared/paciente_avatar.dart';
import '../auth/auth_provider.dart';
import '../visitas/detalle_visita_screen.dart';
import '../visitas/programar_visita_screen.dart';

/// Hoja de abajo con los datos del paciente: dueño, teléfono, estado y próxima visita.
/// La usan el Mapa y Mis pacientes. Devuelve true si algo cambió (para recargar).
Future<bool?> mostrarResumenPaciente(BuildContext context, PacienteConVisitas item) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _ResumenPaciente(item),
  );
}

class _ResumenPaciente extends StatelessWidget {
  const _ResumenPaciente(this.item);

  final PacienteConVisitas item;

  @override
  Widget build(BuildContext context) {
    final p = item.paciente;
    final proxima = item.proximaVisita;
    final rol = context.read<AuthProvider>().sesion?.rol;
    final puedeProgramar = rol == Roles.tecnico || rol == Roles.medico;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: PacienteAvatar(p, color: item.estado.color, radio: 28),
              title: Text(p.nombre, style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text('${p.especieNombre} · ${p.razaNombre}'),
            ),
            Row(children: [
              Icon(Icons.circle, size: 12, color: item.estado.color),
              const SizedBox(width: 6),
              Text(item.estado.etiqueta, style: TextStyle(color: item.estado.color, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text('Dueño: ${p.duenoNombre}'),
            Text('Teléfono: ${p.duenoTelefono ?? '-'}'),
            const SizedBox(height: 8),
            Text('Próxima visita: ${item.textoProximaVisita}'),
            const SizedBox(height: 16),
            if (proxima != null)
              FilledButton.icon(
                icon: const Icon(Icons.event_note),
                label: const Text('Abrir próxima visita'),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetalleVisitaScreen(visitaId: proxima.id)),
                  );
                  if (context.mounted) Navigator.pop(context, true);
                },
              ),
            if (puedeProgramar) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_available),
                label: const Text('Programar visita'),
                onPressed: () async {
                  final programada = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => ProgramarVisitaScreen(pacienteInicial: p)),
                  );
                  if (context.mounted) Navigator.pop(context, programada == true);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}