import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../data/models/visita.dart';
import '../../data/repositories/visitas_repository.dart';

/// Formulario de registro de visita [p4]: peso, altura, temperatura,
/// condición corporal, observaciones, ubicación de la casa (GPS) y foto (cámara o galería).
class RegistrarVisitaScreen extends StatefulWidget {
  const RegistrarVisitaScreen({super.key, required this.visita});

  final Visita visita;

  @override
  State<RegistrarVisitaScreen> createState() => _RegistrarVisitaScreenState();
}

class _RegistrarVisitaScreenState extends State<RegistrarVisitaScreen> {
  static const int _maxFotoBytes = 5 * 1024 * 1024; // 5 MB, igual que la API

  /// Escala de condición corporal de 1 a 9 (la API recibe texto).
  static const List<String> _condiciones = [
    '1 - Caquéctico',
    '2 - Muy delgado',
    '3 - Delgado',
    '4 - Ideal bajo',
    '5 - Ideal',
    '6 - Ideal alto',
    '7 - Sobrepeso',
    '8 - Obeso',
    '9 - Obesidad severa',
  ];

  final _formKey = GlobalKey<FormState>();
  final _peso = TextEditingController();
  final _altura = TextEditingController();
  final _temperatura = TextEditingController();
  final _observaciones = TextEditingController();
  String? _condicion;
  Position? _ubicacion;
  bool _buscandoUbicacion = false;
  String? _errorUbicacion;
  XFile? _foto;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _peso.dispose();
    _altura.dispose();
    _temperatura.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  // ---------- GPS ----------
  Future<void> _obtenerUbicacion() async {
    setState(() {
      _buscandoUbicacion = true;
      _errorUbicacion = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Activa la ubicación (GPS) del teléfono.';
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        throw 'Sin permiso de ubicación. Actívalo en Ajustes > Apps > VetRuta > Permisos.';
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) throw 'No se pudo obtener la ubicación. Intenta de nuevo.';
      if (mounted) setState(() => _ubicacion = pos);
    } catch (e) {
      if (mounted) setState(() => _errorUbicacion = e.toString());
    } finally {
      if (mounted) setState(() => _buscandoUbicacion = false);
    }
  }

  // ---------- Foto ----------
  Future<void> _elegirFoto(ImageSource origen) async {
    final foto = await ImagePicker().pickImage(
      source: origen,
      maxWidth: 1600, // reduce el tamaño para no pasar de 5 MB
      imageQuality: 80,
    );
    if (foto == null) return; // el usuario canceló
    final nombre = foto.name.toLowerCase();
    if (!(nombre.endsWith('.jpg') || nombre.endsWith('.jpeg') || nombre.endsWith('.png'))) {
      _aviso('La foto debe ser JPG o PNG.');
      return;
    }
    if (await foto.length() > _maxFotoBytes) {
      _aviso('La foto no puede pesar más de 5 MB.');
      return;
    }
    setState(() => _foto = foto);
  }

  // ---------- Guardar ----------
  double? _numero(String texto) => double.tryParse(texto.trim().replaceAll(',', '.'));

  String? Function(String?) _validarRango(String campo, double min, double max, {bool minIncluido = false}) {
    return (texto) {
      final n = _numero(texto ?? '');
      if (n == null) return 'Escribe $campo';
      final debajo = minIncluido ? n < min : n <= min;
      if (debajo || n > max) return '$campo debe estar entre ${min.toStringAsFixed(0)} y ${max.toStringAsFixed(0)}';
      return null;
    };
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ubicacion == null) {
      _aviso('Falta la ubicación de la casa. Toca "Obtener ubicación".');
      return;
    }
    if (_foto == null) {
      _aviso('Falta la foto de la visita (evidencia).');
      return;
    }
    setState(() => _guardando = true);
    try {
      await VisitasRepository(context.read<ApiClient>()).registrar(
        widget.visita.id,
        RegistroVisita(
          pesoKg: _numero(_peso.text)!,
          alturaCm: _numero(_altura.text)!,
          temperatura: _numero(_temperatura.text)!,
          condicion: _condicion!,
          observaciones: _observaciones.text.trim().isEmpty ? null : _observaciones.text.trim(),
          latitud: _ubicacion!.latitude,
          longitud: _ubicacion!.longitude,
          rutaFoto: _foto!.path,
        ),
      );
      if (!mounted) return;
      _aviso('Visita registrada.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _aviso(ApiClient.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visita;
    const numeros = TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar visita')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${v.pacienteNombre} · ${v.servicioNombre}', style: Theme.of(context).textTheme.titleMedium),
            Text('Dueño: ${v.duenoNombre}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _peso,
              keyboardType: numeros,
              decoration: const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder()),
              validator: _validarRango('el peso', 0, 1000),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _altura,
              keyboardType: numeros,
              decoration: const InputDecoration(labelText: 'Altura (cm)', border: OutlineInputBorder()),
              validator: _validarRango('la altura', 0, 300),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _temperatura,
              keyboardType: numeros,
              decoration: const InputDecoration(labelText: 'Temperatura (°C)', border: OutlineInputBorder()),
              validator: _validarRango('la temperatura', 30, 45, minIncluido: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _condicion,
              decoration: const InputDecoration(labelText: 'Condición corporal (1 a 9)', border: OutlineInputBorder()),
              items: [for (final c in _condiciones) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (c) => setState(() => _condicion = c),
              validator: (c) => c == null ? 'Elige la condición corporal' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observaciones,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Observaciones (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),

            // Ubicación de la casa
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Ubicación de la casa'),
                subtitle: Text(_buscandoUbicacion
                    ? 'Buscando ubicación...'
                    : _ubicacion != null
                        ? '${_ubicacion!.latitude.toStringAsFixed(6)}, ${_ubicacion!.longitude.toStringAsFixed(6)}'
                        : (_errorUbicacion ?? 'Sin ubicación')),
                trailing: IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Obtener ubicación',
                  onPressed: _buscandoUbicacion ? null : _obtenerUbicacion,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Foto de evidencia
            Text('Foto de la visita', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_foto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_foto!.path), height: 220, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _elegirFoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Cámara'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _elegirFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _guardando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Guardar registro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}