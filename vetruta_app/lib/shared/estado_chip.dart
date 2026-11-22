import 'package:flutter/material.dart';

import '../data/models/visita.dart';

/// Etiqueta de color con el estado de la visita.
class EstadoChip extends StatelessWidget {
  const EstadoChip(this.estado, {super.key});

  final EstadoVisita estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: estado.color.withValues(alpha: 0.15),
        border: Border.all(color: estado.color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(color: estado.color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

/// Fila con los colores de cada estado, para explicar el calendario.
class LeyendaEstados extends StatelessWidget {
  const LeyendaEstados({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final e in EstadoVisita.values)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle, size: 12, color: e.color),
            const SizedBox(width: 4),
            Text(e.etiqueta, style: const TextStyle(fontSize: 12)),
          ]),
      ],
    );
  }
}