import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/api_client.dart';
import '../../data/repositories/usuarios_repository.dart';
import '../auth/auth_provider.dart';
import '../medico/actividades_screen.dart';
import '../medico/pacientes_medico_screen.dart';
import '../tecnico/calendario_screen.dart';
import '../tecnico/mapa_screen.dart';
import '../tecnico/mis_pacientes_screen.dart';
import '../visitas/programar_visita_screen.dart';
import 'pantalla_pendiente.dart';

/// Una opción del menú principal.
class OpcionMenu {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final WidgetBuilder pantalla;

  const OpcionMenu(this.titulo, this.descripcion, this.icono, this.pantalla);
}

/// Opciones que ve cada rol (tabla de permisos del enunciado, págs. 3 y 4).
/// Cuando termines una pantalla, cambia su PantallaPendiente por la pantalla real.
List<OpcionMenu> opcionesDelRol(String rol) {
  switch (rol) {
    case Roles.root:
      return [
        OpcionMenu('Usuarios', 'Crear, activar y desactivar usuarios', Icons.manage_accounts,
            (_) => const PantallaPendiente('Usuarios')),
      ];
    case Roles.director:
      return [
        OpcionMenu('Asignar técnicos', 'Asignar o reasignar técnicos a médicos', Icons.swap_horiz,
            (_) => const PantallaPendiente('Asignar técnicos')),
        OpcionMenu('Actividades', 'Personal, pacientes y visitas', Icons.list_alt,
            (_) => const PantallaPendiente('Actividades')),
        OpcionMenu('Tablero', 'Gráficas de visitas y pacientes', Icons.bar_chart,
            (_) => const PantallaPendiente('Tablero')),
      ];
    case Roles.medico:
      return [
        OpcionMenu('Pacientes', 'Crear, asignar técnico e historial', Icons.pets,
            (_) => const PacientesMedicoScreen()),
        OpcionMenu('Programar visita', 'Agendar una visita con un servicio', Icons.event_available,
            (_) => const ProgramarVisitaScreen()),
        OpcionMenu('Actividades de mis técnicos', 'Visitas hechas, pendientes y atrasadas',
            Icons.list_alt,
            (_) => ActividadesScreen(
                  titulo: 'Actividades de mis técnicos',
                  cargarTecnicos: (ctx) => UsuariosRepository(ctx.read<ApiClient>())
                      .tecnicosDeMedico(ctx.read<AuthProvider>().sesion!.usuarioId),
                )),
        OpcionMenu('Tablero', 'Gráficas de mis técnicos', Icons.bar_chart,
            (_) => const PantallaPendiente('Tablero')),
      ];
    case Roles.tecnico:
      return [
        OpcionMenu('Calendario', 'Mis visitas por día y su estado', Icons.calendar_month,
            (_) => const CalendarioScreen()),
        OpcionMenu('Mapa', 'Dónde están mis pacientes', Icons.map,
            (_) => const MapaScreen()),
        OpcionMenu('Mis pacientes', 'Pacientes asignados y próxima visita', Icons.pets,
            (_) => const MisPacientesScreen()),
        OpcionMenu('Programar visita', 'Agendar una visita a uno de mis pacientes',
            Icons.event_available, (_) => const ProgramarVisitaScreen()),
        OpcionMenu('Tablero', 'Mis gráficas', Icons.bar_chart,
            (_) => const PantallaPendiente('Tablero')),
      ];
    default:
      return [];
  }
}
