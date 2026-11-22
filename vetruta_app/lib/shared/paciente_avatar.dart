import 'package:flutter/material.dart';

import '../data/models/paciente.dart';

/// Foto redonda de la mascota; si no tiene foto, muestra una huella.
class PacienteAvatar extends StatelessWidget {
  const PacienteAvatar(this.paciente, {super.key, this.color, this.radio = 24});

  final Paciente paciente;
  final Color? color;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final foto = paciente.fotoCompleta;
    return CircleAvatar(
      radius: radio,
      backgroundColor: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.2),
      foregroundImage: foto == null ? null : NetworkImage(foto),
      child: Icon(Icons.pets, color: color),
    );
  }
}
