import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../auth/auth_provider.dart';
import 'menu_por_rol.dart';

/// Menú principal: muestra solo las opciones del rol del usuario.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmarSalida(BuildContext context) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres salir de VetRuta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    if (salir == true && context.mounted) {
      await context.read<AuthProvider>().cerrarSesion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<AuthProvider>().sesion;
    if (sesion == null) return const SizedBox.shrink();
    final opciones = opcionesDelRol(sesion.rol);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VetRuta'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmarSalida(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(sesion.nombre),
              subtitle: Text('Rol: ${Roles.etiqueta(sesion.rol)}'),
            ),
          ),
          const SizedBox(height: 8),
          if (opciones.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Tu rol no tiene opciones en la app.', textAlign: TextAlign.center),
            ),
          for (final op in opciones)
            Card(
              child: ListTile(
                leading: Icon(op.icono, color: Theme.of(context).colorScheme.primary),
                title: Text(op.titulo),
                subtitle: Text(op.descripcion),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: op.pantalla)),
              ),
            ),
        ],
      ),
    );
  }
}