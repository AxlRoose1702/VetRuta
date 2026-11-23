import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../data/repositories/usuarios_repository.dart';
import '../auth/auth_provider.dart';
import '../director/actividades_director_screen.dart';
import '../director/asignar_tecnicos_screen.dart';
import '../medico/actividades_screen.dart';
import '../medico/pacientes_medico_screen.dart';
import '../root/usuarios_screen.dart';
import '../tablero/tablero_screen.dart';
import '../tecnico/calendario_screen.dart';
import '../tecnico/mapa_screen.dart';
import '../tecnico/mis_pacientes_screen.dart';
import '../visitas/programar_visita_screen.dart';

/// Una opción del menú principal.
class OpcionMenu {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final WidgetBuilder pantalla;

  const OpcionMenu(this.titulo, this.descripcion, this.icono, this.pantalla);
}

/// Opciones que ve cada rol (tabla de permisos del enunciado, págs. 3 y 4).
/// La API además valida el rol en cada endpoint: la regla está en la app y en el backend [p5].
List<OpcionMenu> opcionesDelRol(String rol) {
  final tablero = OpcionMenu(
    'Tablero',
    'Gráficas de visitas y pacientes',
    Icons.bar_chart,
    (_) => const TableroScreen(),
  );
  final programar = OpcionMenu(
    'Programar visita',
    'Agendar una visita con un servicio',
    Icons.event_available,
    (_) => const ProgramarVisitaScreen(),
  );

  switch (rol) {
    case Roles.root:
      return [
        OpcionMenu(
          'Usuarios',
          'Crear, activar y desactivar usuarios',
          Icons.manage_accounts,
          (_) => const UsuariosScreen(),
        ),
      ];
    case Roles.director:
      return [
        OpcionMenu(
          'Asignar técnicos',
          'Asignar o reasignar técnicos a médicos',
          Icons.swap_horiz,
          (_) => const AsignarTecnicosScreen(),
        ),
        OpcionMenu(
          'Actividades',
          'Personal, pacientes y visitas',
          Icons.list_alt,
          (_) => const ActividadesDirectorScreen(),
        ),
        tablero,
      ];
    case Roles.medico:
      return [
        OpcionMenu('Pacientes', 'Crear, asignar técnico e historial', Icons.pets, (_) => const PacientesMedicoScreen()),
        programar,
        OpcionMenu(
          'Actividades de mis técnicos',
          'Visitas hechas, pendientes y atrasadas',
          Icons.list_alt,
          (_) => ActividadesScreen(
            titulo: 'Actividades de mis técnicos',
            cargarTecnicos: (ctx) =>
                UsuariosRepository(ctx.read<ApiClient>()).tecnicosDeMedico(ctx.read<AuthProvider>().sesion!.usuarioId),
          ),
        ),
        tablero,
      ];
    case Roles.tecnico:
      return [
        OpcionMenu(
          'Calendario',
          'Mis visitas por día y su estado',
          Icons.calendar_month,
          (_) => const CalendarioScreen(),
        ),
        OpcionMenu('Mapa', 'Dónde están mis pacientes', Icons.map, (_) => const MapaScreen()),
        OpcionMenu(
          'Mis pacientes',
          'Pacientes asignados y próxima visita',
          Icons.pets,
          (_) => const MisPacientesScreen(),
        ),
        programar,
        tablero,
      ];
    default:
      return [];
  }
}
