import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../data/models/catalogos.dart';
import '../../data/repositories/usuarios_repository.dart';
import '../auth/auth_provider.dart';
import 'crear_usuario_screen.dart';

/// Root: lista de usuarios (2.3) [p3, p4]. Filtrar por rol, activar o desactivar y crear.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  static const _roles = [Roles.director, Roles.medico, Roles.tecnico, Roles.root];
  String? _rol;
  List<Usuario> _usuarios = [];
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
      final u = await _repo.listar(rol: _rol);
      if (mounted) setState(() => _usuarios = u);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarActivo(Usuario u, bool activo) async {
    try {
      await _repo.cambiarActivo(u.id, activo);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${u.nombre} ${activo ? 'activado' : 'desactivado'}.')));
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.mensajeDeError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final miId = context.watch<AuthProvider>().sesion?.usuarioId;
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Crear usuario'),
        onPressed: () async {
          final creado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CrearUsuarioScreen()),
          );
          if (creado == true) _cargar();
        },
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('Todos'),
                    selected: _rol == null,
                    onSelected: (_) {
                      setState(() => _rol = null);
                      _cargar();
                    },
                  ),
                ),
                for (final r in _roles)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(Roles.etiqueta(r)),
                      selected: _rol == r,
                      onSelected: (_) {
                        setState(() => _rol = r);
                        _cargar();
                      },
                    ),
                  ),
              ],
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
                  for (final u in _usuarios)
                    SwitchListTile(
                      value: u.activo,
                      // Root no puede cambiar su propio estado (regla de la API).
                      onChanged: u.id == miId ? null : (v) => _cambiarActivo(u, v),
                      title: Text(u.nombre),
                      subtitle: Text(
                        '${u.email ?? ''}\n${Roles.etiqueta(u.rol ?? '')}'
                        '${u.zonaNombre != null ? ' · ${u.zonaNombre}' : ''}'
                        ' · ${u.activo ? 'Activo' : 'Inactivo'}',
                      ),
                      isThreeLine: true,
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
