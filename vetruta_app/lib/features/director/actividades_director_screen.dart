import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../data/models/catalogos.dart';
import '../../data/models/paciente.dart';
import '../../data/repositories/pacientes_repository.dart';
import '../../data/repositories/usuarios_repository.dart';
import '../../shared/paciente_avatar.dart';
import '../medico/actividades_screen.dart';
import '../pacientes/historial_screen.dart';

/// Director: actividades de todo el personal (2.7) [p4]: personal, pacientes y visitas.
class ActividadesDirectorScreen extends StatelessWidget {
  const ActividadesDirectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void ir(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(title: const Text('Actividades')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Personal'),
              subtitle: const Text('Médicos y sus técnicos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ir(const _PersonalScreen()),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Pacientes'),
              subtitle: const Text('Todos, con especie, dueño y técnico'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ir(const _PacientesScreen()),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Visitas'),
              subtitle: const Text('Pendientes, atrasadas, realizadas y canceladas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ir(
                ActividadesScreen(
                  titulo: 'Visitas de todo el personal',
                  cargarTecnicos: (ctx) => UsuariosRepository(ctx.read<ApiClient>()).listar(rol: Roles.tecnico),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Médicos con sus técnicos, y los técnicos que aún no tienen médico.
class _PersonalScreen extends StatelessWidget {
  const _PersonalScreen();

  @override
  Widget build(BuildContext context) {
    final repo = UsuariosRepository(context.read<ApiClient>());
    return Scaffold(
      appBar: AppBar(title: const Text('Personal')),
      body: FutureBuilder<List<List<Usuario>>>(
        future: Future.wait([repo.listar(rol: Roles.medico), repo.listar(rol: Roles.tecnico)]),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(ApiClient.mensajeDeError(snap.error!)));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final medicos = snap.data![0];
          final tecnicos = snap.data![1];
          final sinMedico = tecnicos.where((t) => t.medicoId == null).toList();
          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              for (final m in medicos)
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.medical_services),
                    title: Text(m.nombre + (m.activo ? '' : ' (inactivo)')),
                    subtitle: Text('${tecnicos.where((t) => t.medicoId == m.id).length} técnico(s)'),
                    children: [
                      for (final t in tecnicos.where((t) => t.medicoId == m.id))
                        ListTile(
                          leading: const Icon(Icons.engineering),
                          title: Text(t.nombre + (t.activo ? '' : ' (inactivo)')),
                          subtitle: Text('Zona: ${t.zonaNombre ?? '-'}'),
                        ),
                    ],
                  ),
                ),
              if (sinMedico.isNotEmpty)
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.person_off, color: Colors.orange),
                    title: const Text('Técnicos sin médico'),
                    subtitle: Text('${sinMedico.length} técnico(s)'),
                    children: [
                      for (final t in sinMedico)
                        ListTile(title: Text(t.nombre), subtitle: Text('Zona: ${t.zonaNombre ?? '-'}')),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Todos los pacientes (solo lectura). Al tocar uno se abre su historial.
class _PacientesScreen extends StatefulWidget {
  const _PacientesScreen();

  @override
  State<_PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<_PacientesScreen> {
  final _buscar = TextEditingController();
  late Future<List<Paciente>> _futuro = _consultar();

  Future<List<Paciente>> _consultar() =>
      PacientesRepository(context.read<ApiClient>()).listar(buscar: _buscar.text.trim());

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pacientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _buscar,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => setState(() => _futuro = _consultar()),
              decoration: const InputDecoration(
                hintText: 'Buscar paciente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Paciente>>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text(ApiClient.mensajeDeError(snap.error!)));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final lista = snap.data!;
                if (lista.isEmpty) return const Center(child: Text('Sin pacientes'));
                return ListView(
                  children: [
                    for (final p in lista)
                      ListTile(
                        leading: PacienteAvatar(p),
                        title: Text('${p.nombre} (${p.especieNombre} · ${p.razaNombre})'),
                        subtitle: Text('Dueño: ${p.duenoNombre}\nTécnico: ${p.tecnicoNombre ?? 'sin técnico'}'),
                        isThreeLine: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HistorialScreen(pacienteId: p.id)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
