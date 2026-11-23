import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../data/models/catalogos.dart';
import '../../data/repositories/usuarios_repository.dart';

/// Root: crear usuario (2.4) [p4]. Director, Médico o Técnico.
/// Los técnicos trabajan por zonas [p3]; su médico lo asigna después el Director.
class CrearUsuarioScreen extends StatefulWidget {
  const CrearUsuarioScreen({super.key});

  @override
  State<CrearUsuarioScreen> createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends State<CrearUsuarioScreen> {
  static const _roles = [Roles.director, Roles.medico, Roles.tecnico];

  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _rol;
  int? _zonaId;
  List<Zona> _zonas = [];
  bool _ocultar = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    UsuariosRepository(context.read<ApiClient>())
        .zonas()
        .then((z) {
          if (mounted) setState(() => _zonas = z.where((x) => x.activa).toList());
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await UsuariosRepository(context.read<ApiClient>()).crear(
        email: _email.text.trim(),
        password: _password.text,
        nombreCompleto: _nombre.text.trim(),
        rol: _rol!,
        zonaId: _zonaId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario creado.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.mensajeDeError(e))));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const borde = OutlineInputBorder();
    return Scaffold(
      appBar: AppBar(title: const Text('Crear usuario')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre completo', border: borde),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo', border: borde),
              validator: (v) => (v == null || !v.contains('@')) ? 'Correo no válido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _ocultar,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                helperText: 'Mínimo 6 caracteres. Si la API la rechaza, dirá por qué',
                border: borde,
                suffixIcon: IconButton(
                  icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _rol,
              decoration: const InputDecoration(labelText: 'Rol', border: borde),
              items: [for (final r in _roles) DropdownMenuItem(value: r, child: Text(Roles.etiqueta(r)))],
              onChanged: (v) => setState(() => _rol = v),
              validator: (v) => v == null ? 'Elige el rol' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _zonaId,
              decoration: InputDecoration(labelText: _rol == Roles.tecnico ? 'Zona' : 'Zona (opcional)', border: borde),
              items: [for (final z in _zonas) DropdownMenuItem(value: z.id, child: Text(z.nombre))],
              onChanged: (v) => setState(() => _zonaId = v),
              validator: (v) => (_rol == Roles.tecnico && v == null) ? 'El técnico trabaja en una zona' : null,
            ),
            if (_rol == Roles.tecnico)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('El médico del técnico lo asigna después el Director.'),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _guardando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Crear usuario'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
