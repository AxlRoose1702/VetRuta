import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/fechas.dart';
import '../../data/models/catalogos.dart';
import '../../data/repositories/catalogos_repository.dart';
import '../../data/repositories/pacientes_repository.dart';
import '../../data/repositories/usuarios_repository.dart';
import '../../shared/foto_picker.dart';
import '../auth/auth_provider.dart';

/// Crear paciente con su dueño (2.8). Solo el Médico [p4].
/// Mascota: especie, raza, nombre, fecha de nacimiento aproximada, foto [p2];
/// dueño con teléfono y dirección [p2]; técnico asignado (uno de los suyos) [p4].
class CrearPacienteScreen extends StatefulWidget {
  const CrearPacienteScreen({super.key});

  @override
  State<CrearPacienteScreen> createState() => _CrearPacienteScreenState();
}

class _CrearPacienteScreenState extends State<CrearPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();

  List<Especie> _especies = [];
  List<Raza> _razas = [];
  List<Usuario> _tecnicos = [];
  Dueno? _dueno;
  int? _especieId;
  int? _razaId;
  String? _tecnicoId;
  DateTime? _nacimiento;
  XFile? _foto;
  Position? _ubicacion;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarListas();
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _cargarListas() async {
    final api = context.read<ApiClient>();
    final miId = context.read<AuthProvider>().sesion!.usuarioId;
    try {
      final r = await Future.wait([
        CatalogosRepository(api).especies(),
        UsuariosRepository(api).tecnicosDeMedico(miId),
      ]);
      if (!mounted) return;
      setState(() {
        _especies = r[0] as List<Especie>;
        _tecnicos = (r[1] as List<Usuario>).where((t) => t.activo).toList();
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.mensajeDeError(e);
          _cargando = false;
        });
      }
    }
  }

  /// Al cambiar la especie se cargan solo sus razas.
  Future<void> _elegirEspecie(int? id) async {
    setState(() {
      _especieId = id;
      _razaId = null;
      _razas = [];
    });
    if (id == null) return;
    try {
      final razas = await CatalogosRepository(context.read<ApiClient>()).razasDeEspecie(id);
      if (mounted) setState(() => _razas = razas);
    } catch (e) {
      _aviso(ApiClient.mensajeDeError(e));
    }
  }

  Future<void> _elegirDueno() async {
    final dueno = await showDialog<Dueno>(context: context, builder: (_) => const _DialogoDueno());
    if (dueno != null) setState(() => _dueno = dueno);
  }

  Future<void> _elegirNacimiento() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _nacimiento ?? DateTime(hoy.year - 1, hoy.month, hoy.day),
      firstDate: DateTime(hoy.year - 40),
      lastDate: hoy,
      helpText: 'Fecha de nacimiento aproximada',
    );
    if (fecha != null) setState(() => _nacimiento = fecha);
  }

  Future<void> _elegirFoto() async {
    final foto = await preguntarYElegirFoto(context);
    if (foto != null) setState(() => _foto = foto);
  }

  /// (Recomendado) Ubicación de la casa con el GPS, si el médico está ahí.
  Future<void> _usarGps() async {
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        _aviso('Sin permiso de ubicación.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      if (mounted) setState(() => _ubicacion = pos);
    } catch (_) {
      _aviso('No se pudo obtener la ubicación.');
    }
  }

  void _aviso(String texto) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueno == null) {
      _aviso('Elige o crea el dueño.');
      return;
    }
    setState(() => _guardando = true);
    final repo = PacientesRepository(context.read<ApiClient>());
    try {
      // 1. Crear el paciente.
      final paciente = await repo.crear(
        nombre: _nombre.text.trim(),
        fechaNacimiento: _nacimiento,
        razaId: _razaId!,
        duenoId: _dueno!.id,
        tecnicoId: _tecnicoId!,
        latitud: _ubicacion?.latitude,
        longitud: _ubicacion?.longitude,
      );
      // 2. Subir la foto en una segunda llamada (así lo pide la API).
      if (_foto != null) {
        try {
          await repo.subirFoto(paciente.id, _foto!.path);
        } catch (e) {
          _aviso('Paciente creado, pero la foto falló: ${ApiClient.mensajeDeError(e)}');
        }
      }
      if (!mounted) return;
      _aviso('Paciente creado.');
      Navigator.pop(context, true);
    } catch (e) {
      _aviso(ApiClient.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borde = const OutlineInputBorder();
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo paciente')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Dueño', style: Theme.of(context).textTheme.titleMedium),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(_dueno?.nombre ?? 'Toca para buscar o crear el dueño'),
                          subtitle: _dueno == null
                              ? null
                              : Text('Tel: ${_dueno!.telefono ?? '-'}\n${_dueno!.direccion ?? ''}'),
                          trailing: const Icon(Icons.search),
                          onTap: _elegirDueno,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Mascota', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombre,
                        decoration: InputDecoration(labelText: 'Nombre', border: borde),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _especieId,
                        decoration: InputDecoration(labelText: 'Especie', border: borde),
                        items: [for (final e in _especies) DropdownMenuItem(value: e.id, child: Text(e.nombre))],
                        onChanged: _elegirEspecie,
                        validator: (v) => v == null ? 'Elige la especie' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        key: ValueKey(_especieId), // se reinicia al cambiar de especie
                        initialValue: _razaId,
                        decoration: InputDecoration(labelText: 'Raza', border: borde),
                        items: [for (final r in _razas) DropdownMenuItem(value: r.id, child: Text(r.nombre))],
                        onChanged: (v) => setState(() => _razaId = v),
                        validator: (v) => v == null ? 'Elige la raza' : null,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.cake),
                          title: const Text('Fecha de nacimiento aproximada'),
                          subtitle: Text(_nacimiento == null ? 'Opcional' : Fechas.soloFecha(_nacimiento!)),
                          onTap: _elegirNacimiento,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _tecnicoId,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: 'Técnico asignado', border: borde),
                        items: [
                          for (final t in _tecnicos)
                            DropdownMenuItem(
                              value: t.id,
                              child: Text('${t.nombre}${t.zonaNombre != null ? ' · ${t.zonaNombre}' : ''}'),
                            ),
                        ],
                        onChanged: (v) => setState(() => _tecnicoId = v),
                        validator: (v) => v == null ? 'Elige el técnico' : null,
                      ),
                      if (_tecnicos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('No tienes técnicos. El Director debe asignártelos.'),
                        ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.location_on),
                          title: const Text('Ubicación de la casa (opcional)'),
                          subtitle: Text(_ubicacion == null
                              ? 'Si no la pones, se guarda en la primera visita registrada'
                              : '${_ubicacion!.latitude.toStringAsFixed(5)}, ${_ubicacion!.longitude.toStringAsFixed(5)}'),
                          trailing: IconButton(icon: const Icon(Icons.my_location), onPressed: _usarGps),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Foto de la mascota', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (_foto != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_foto!.path), height: 200, fit: BoxFit.cover),
                        ),
                      OutlinedButton.icon(
                        onPressed: _elegirFoto,
                        icon: const Icon(Icons.add_a_photo),
                        label: Text(_foto == null ? 'Agregar foto (cámara o galería)' : 'Cambiar foto'),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _guardando
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Guardar paciente'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

/// Diálogo para buscar un dueño existente o crear uno nuevo.
class _DialogoDueno extends StatefulWidget {
  const _DialogoDueno();

  @override
  State<_DialogoDueno> createState() => _DialogoDuenoState();
}

class _DialogoDuenoState extends State<_DialogoDueno> {
  final _buscar = TextEditingController();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  List<Dueno> _resultados = [];
  bool _creando = false;
  bool _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hacerBusqueda();
  }

  @override
  void dispose() {
    for (final c in [_buscar, _nombre, _telefono, _direccion]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _hacerBusqueda() async {
    setState(() => _ocupado = true);
    try {
      final r = await CatalogosRepository(context.read<ApiClient>()).buscarDuenos(_buscar.text.trim());
      if (mounted) setState(() => _resultados = r);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _crear() async {
    if (_nombre.text.trim().isEmpty) {
      setState(() => _error = 'Escribe el nombre del dueño');
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final d = await CatalogosRepository(context.read<ApiClient>()).crearDueno(
        nombre: _nombre.text.trim(),
        telefono: _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
        direccion: _direccion.text.trim().isEmpty ? null : _direccion.text.trim(),
      );
      if (mounted) Navigator.pop(context, d);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_creando ? 'Nuevo dueño' : 'Buscar dueño'),
      content: SizedBox(
        width: double.maxFinite,
        child: _creando
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre')),
                TextField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                TextField(controller: _direccion, decoration: const InputDecoration(labelText: 'Dirección')),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: _buscar,
                  decoration: InputDecoration(
                    labelText: 'Nombre o teléfono',
                    suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _hacerBusqueda),
                  ),
                  onSubmitted: (_) => _hacerBusqueda(),
                ),
                if (_ocupado) const LinearProgressIndicator(),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                Flexible(
                  child: ListView(shrinkWrap: true, children: [
                    for (final d in _resultados)
                      ListTile(
                        title: Text(d.nombre),
                        subtitle: Text(d.telefono ?? '-'),
                        onTap: () => Navigator.pop(context, d),
                      ),
                    if (!_ocupado && _resultados.isEmpty) const ListTile(title: Text('Sin resultados')),
                  ]),
                ),
              ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        if (_creando)
          FilledButton(onPressed: _ocupado ? null : _crear, child: const Text('Crear dueño'))
        else
          FilledButton.icon(
            onPressed: () => setState(() {
              _creando = true;
              _error = null;
              _nombre.text = _buscar.text;
            }),
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo'),
          ),
      ],
    );
  }
}
