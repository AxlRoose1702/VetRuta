import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../data/models/catalogos.dart';
import '../../data/repositories/usuarios_repository.dart';

/// Director: asignar técnicos a médicos (2.5) [p3, p4].
/// Un técnico pertenece a un solo médico a la vez; se puede reasignar o quitar.
class AsignarTecnicosScreen extends StatefulWidget {
  const AsignarTecnicosScreen({super.key});

  @override
  State<AsignarTecnicosScreen> createState() => _AsignarTecnicosScreenState();
}

class _AsignarTecnicosScreenState extends State<AsignarTecnicosScreen> {
  List<Usuario> _tecnicos = [];
  List<Usuario> _medicos = [];
  bool _cargando = true;
  String? _error;

  UsuariosRepository get _repo => UsuariosRepository(context.read<ApiClient>());

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await Future.wait([_repo.listar(rol: Roles.tecnico), _repo.listar(rol: Roles.medico, activo: true)]);
      if (mounted) {
        setState(() {
          _tecnicos = r[0];
          _medicos = r[1];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _aviso(String texto) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _elegirMedico(Usuario tecnico) async {
    // '' significa "quitar médico".
    final elegido = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Médico de ${tecnico.nombre}'),
        children: [
          for (final m in _medicos)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m.id),
              child: Row(
                children: [
                  Icon(m.id == tecnico.medicoId ? Icons.radio_button_checked : Icons.radio_button_off, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(m.nombre)),
                ],
              ),
            ),
          if (tecnico.medicoId != null)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Row(
                children: [
                  Icon(Icons.link_off, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Quitar médico', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
        ],
      ),
    );
    if (elegido == null || elegido == tecnico.medicoId) return;
    try {
      if (elegido.isEmpty) {
        await _repo.quitarMedico(tecnico.id);
        _aviso('Se quitó el médico de ${tecnico.nombre}.');
      } else {
        await _repo.asignarMedico(tecnico.id, elegido);
        _aviso(tecnico.medicoId == null ? 'Técnico asignado.' : 'Técnico reasignado.');
      }
      _cargar();
    } catch (e) {
      _aviso(ApiClient.mensajeDeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignar técnicos')),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          children: [
            if (_cargando) const LinearProgressIndicator(),
            if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Toca un técnico para asignarlo, reasignarlo o quitarle el médico. '
                'Cada técnico pertenece a un solo médico.',
              ),
            ),
            for (final t in _tecnicos)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: t.medicoId == null ? Colors.orange.shade100 : Colors.teal.shade100,
                  child: Icon(t.medicoId == null ? Icons.person_off : Icons.engineering),
                ),
                title: Text(t.nombre + (t.activo ? '' : ' (inactivo)')),
                subtitle: Text('Médico: ${t.medicoNombre ?? 'sin asignar'}\nZona: ${t.zonaNombre ?? '-'}'),
                isThreeLine: true,
                trailing: const Icon(Icons.edit),
                onTap: () => _elegirMedico(t),
              ),
          ],
        ),
      ),
    );
  }
}
