import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../data/models/paciente.dart';
import '../../data/repositories/pacientes_repository.dart';
import '../../data/repositories/visitas_repository.dart';
import '../../shared/paciente_avatar.dart';
import '../pacientes/paciente_resumen_sheet.dart';
import 'pacientes_tecnico_provider.dart';

/// Mis pacientes (2.17): los pacientes asignados al técnico y su próxima visita.
/// Marca los que no tienen visita programada, porque debe visitarlos a todos [p4].
class MisPacientesScreen extends StatelessWidget {
  const MisPacientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final api = ctx.read<ApiClient>();
        return PacientesTecnicoProvider(PacientesRepository(api), VisitasRepository(api));
      },
      child: const _MisPacientesVista(),
    );
  }
}

class _MisPacientesVista extends StatelessWidget {
  const _MisPacientesVista();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PacientesTecnicoProvider>();
    final sinVisita = prov.pacientes.where((p) => p.estado == EstadoPaciente.sinVisita).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pacientes')),
      body: RefreshIndicator(
        onRefresh: prov.cargar,
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            if (prov.cargando && prov.pacientes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (prov.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(prov.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (!prov.cargando && prov.error == null && prov.pacientes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No tienes pacientes asignados.')),
              ),
            if (prov.pacientes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${prov.pacientes.length} paciente(s) asignado(s)'
                  '${sinVisita > 0 ? ' · $sinVisita sin visita programada' : ''}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            for (final item in prov.pacientes)
              Card(
                child: ListTile(
                  leading: PacienteAvatar(item.paciente, color: item.estado.color),
                  title: Text('${item.paciente.nombre} (${item.paciente.especieNombre})'),
                  subtitle: Text(
                    'Dueño: ${item.paciente.duenoNombre} · ${item.paciente.duenoTelefono ?? '-'}\n'
                    'Próxima: ${item.textoProximaVisita}',
                  ),
                  isThreeLine: true,
                  trailing: Icon(Icons.circle, size: 14, color: item.estado.color),
                  onTap: () async {
                    final cambio = await mostrarResumenPaciente(context, item);
                    if (cambio == true) prov.cargar();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
