import 'package:flutter/material.dart';

/// Pantalla temporal para las opciones que aún no están hechas.
class PantallaPendiente extends StatelessWidget {
  const PantallaPendiente(this.titulo, {super.key});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: const Center(child: Text('En construcción')),
    );
  }
}
