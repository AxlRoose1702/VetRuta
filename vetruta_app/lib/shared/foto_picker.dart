import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Abre la cámara o la galería y valida lo mismo que la API: JPG o PNG, máximo 5 MB.
/// Devuelve null si el usuario cancela o la foto no sirve (y muestra el motivo).
Future<XFile?> elegirFoto(BuildContext context, ImageSource origen) async {
  final foto = await ImagePicker().pickImage(source: origen, maxWidth: 1600, imageQuality: 80);
  if (foto == null || !context.mounted) return null;
  final nombre = foto.name.toLowerCase();
  String? error;
  if (!(nombre.endsWith('.jpg') || nombre.endsWith('.jpeg') || nombre.endsWith('.png'))) {
    error = 'La foto debe ser JPG o PNG.';
  } else if (await foto.length() > 5 * 1024 * 1024) {
    error = 'La foto no puede pesar más de 5 MB.';
  }
  if (error != null) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    return null;
  }
  return foto;
}

/// Pregunta "Cámara o Galería" en una hoja de abajo y devuelve la foto elegida.
Future<XFile?> preguntarYElegirFoto(BuildContext context) async {
  final origen = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.photo_camera),
          title: const Text('Cámara'),
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('Galería'),
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
        ),
      ]),
    ),
  );
  if (origen == null || !context.mounted) return null;
  return elegirFoto(context, origen);
}
