import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../data/models/catalogos.dart';
import '../../data/models/paciente.dart';
import '../../data/repositories/pacientes_repository.dart';
import '../../data/repositories/usuarios_repository.dart';
import '../../shared/foto_picker.dart';
import '../../shared/paciente_avatar.dart';
import '../auth/auth_provider.dart';
import '../pacientes/historial_screen.dart';
import '../visitas/programar_visita_screen.dart';
import 'crear_paciente_screen.dart';

/// Pacientes del médico (2.9): buscar, crear, cambiar técnico, historial y programar visita.
class PacientesMedicoScreen extends StatefulWidget {
  const PacientesMedicoScreen({super.key});

  @override
  State<PacientesMedicoScreen> createState() => _PacientesMedicoScreenState();
}

class _PacientesMedicoScreenState extends State<PacientesMedicoScreen> {
  final _buscar = TextEditingController();
  List<Paciente> _pacientes = [];
  List<Usuario> _tecnicos = [];
  bool _cargando = true;
  String? _error;

  PacientesRepository get _repo => PacientesRepository(context.read<ApiClient>());

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarTecnicos();
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _repo.listar(buscar: _buscar.text.trim());
      if (mounted) setState(() => _pacientes = lista);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarTecnicos() async {
    try {
      final miId = context.read<AuthProvider>().sesion!.usuarioId;
      final t = await UsuariosRepository(context.read<ApiClient>()).tecnicosDeMedico(miId);
      if (mounted) setState(() => _tecnicos = t.where((x) => x.activo).toList());
    } catch (_) {
      /* se avisa al intentar cambiar el técnico */
    }
  }

  void _aviso(String texto) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _cambiarTecnico(Paciente p) async {
    if (_tecnicos.isEmpty) {
      _aviso('No tienes técnicos asignados. El Director debe asignártelos.');
      return;
    }
    final elegido = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Técnico de ${p.nombre}'),
        children: [
          for (final t in _tecnicos)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t.id),
              child: Row(
                children: [
                  Icon(t.id == p.tecnicoId ? Icons.radio_button_checked : Icons.radio_button_off, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${t.nombre}${t.zonaNombre != null ? ' · ${t.zonaNombre}' : ''}')),
                ],
              ),
            ),
        ],
      ),
    );
    if (elegido == null || elegido == p.tecnicoId) return;
    try {
      await _repo.cambiarTecnico(p.id, elegido);
      _aviso('Técnico actualizado.');
      _cargar();
    } catch (e) {
      _aviso(ApiClient.mensajeDeError(e));
    }
  }

  Future<void> _cambiarFoto(Paciente p) async {
    final foto = await preguntarYElegirFoto(context);
    if (foto == null) return;
    try {
      await _repo.subirFoto(p.id, foto.path);
      _aviso('Foto actualizada.');
      _cargar();
    } catch (e) {
      _aviso(ApiClient.mensajeDeError(e));
    }
  }

  Future<void> _ir(Widget pantalla) async {
    final cambio = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => pantalla));
    if (cambio == true) _cargar();
  }

  void _opciones(Paciente p) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        void accion(VoidCallback f) {
          Navigator.pop(ctx);
          f();
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: PacienteAvatar(p),
                  title: Text(p.nombre),
                  subtitle: Text('${p.especieNombre} · ${p.razaNombre} · Dueño: ${p.duenoNombre}'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Ver historial'),
                  onTap: () => accion(() => _ir(HistorialScreen(pacienteId: p.id))),
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('Cambiar técnico'),
                  subtitle: Text('Actual: ${p.tecnicoNombre ?? 'sin técnico'}'),
                  onTap: () => accion(() => _cambiarTecnico(p)),
                ),
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: const Text('Programar visita'),
                  onTap: () => accion(() => _ir(ProgramarVisitaScreen(pacienteInicial: p))),
                ),
                ListTile(
                  leading: const Icon(Icons.add_a_photo),
                  title: const Text('Cambiar foto'),
                  onTap: () => accion(() => _cambiarFoto(p)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pacientes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ir(const CrearPacienteScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo paciente'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _buscar,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _cargar(),
              decoration: InputDecoration(
                hintText: 'Buscar paciente',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _buscar.clear();
                    _cargar();
                  },
                ),
              ),
            ),
          ),
          if (_cargando) const LinearProgressIndicator(),
          if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  if (!_cargando && _pacientes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Sin pacientes')),
                    ),
                  for (final p in _pacientes)
                    ListTile(
                      leading: PacienteAvatar(p),
                      title: Text(p.nombre),
                      subtitle: Text(
                        '${p.especieNombre} · ${p.razaNombre}\n'
                        'Dueño: ${p.duenoNombre} · Técnico: ${p.tecnicoNombre ?? 'sin técnico'}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.more_vert),
                      onTap: () => _opciones(p),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
