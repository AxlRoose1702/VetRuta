import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:vetruta_app/core/api_client.dart';
import 'package:vetruta_app/core/sesion.dart';
import 'package:vetruta_app/data/repositories/usuarios_repository.dart';
import 'package:vetruta_app/features/auth/auth_provider.dart';
import 'package:vetruta_app/features/medico/actividades_screen.dart';
import 'package:vetruta_app/features/medico/crear_paciente_screen.dart';
import 'package:vetruta_app/features/medico/pacientes_medico_screen.dart';
import 'package:vetruta_app/features/pacientes/historial_screen.dart';

final pac = {
  'id': 1,
  'nombre': 'Firulais',
  'fechaNacimiento': '2022-01-01T00:00:00',
  'razaId': 1,
  'razaNombre': 'Labrador',
  'especieId': 1,
  'especieNombre': 'Perro',
  'duenoId': 1,
  'duenoNombre': 'Juan',
  'duenoTelefono': '5555',
  'tecnicoId': 'abc',
  'tecnicoNombre': 'Tec Uno',
  'fotoUrl': null,
  'latitud': null,
  'longitud': null,
};
Map<String, dynamic> vis(int id, String est, double? peso, String reg) => {
  'id': id,
  'pacienteId': 1,
  'pacienteNombre': 'Firulais',
  'especieNombre': 'Perro',
  'duenoNombre': 'Juan',
  'servicioId': 1,
  'servicioNombre': 'Control de peso',
  'tecnicoId': 'abc',
  'tecnicoNombre': 'Tec Uno',
  'fechaProgramada': reg,
  'estado': est,
  'atrasada': false,
  'fechaRegistro': est == 'Realizada' ? reg : null,
  'pesoKg': peso,
  'alturaCm': 40,
  'temperatura': 38,
  'condicion': '5 - Ideal',
  'latitud': null,
  'longitud': null,
  'fotoUrl': null,
  'observaciones': null,
};

ApiClient fake() {
  final api = ApiClient();
  api.dio.interceptors.insert(
    0,
    InterceptorsWrapper(
      onRequest: (o, h) {
        dynamic d;
        final p = o.path;
        if (p == '/api/pacientes') d = [pac];
        if (p == '/api/especies') {
          d = [
            {'id': 1, 'nombre': 'Perro'},
          ];
        }
        if (p == '/api/especies/1/razas') {
          d = [
            {'id': 1, 'nombre': 'Labrador', 'especieId': 1},
          ];
        }
        if (p.startsWith('/api/usuarios/medicos/')) {
          d = [
            {
              'id': 'abc',
              'email': 't@v.com',
              'nombreCompleto': 'Tec Uno',
              'rol': 'Tecnico',
              'activo': true,
              'zonaNombre': 'Zona 1',
            },
          ];
        }
        if (p == '/api/pacientes/1/historial') {
          d = {
            'paciente': pac,
            'totalVisitas': 3,
            'visitasRealizadas': 2,
            'ultimaVisita': null,
            'visitas': [
              vis(3, 'Programada', null, '2026-11-25T10:00:00'),
              vis(2, 'Realizada', 12.0, '2026-11-10T10:00:00'),
              vis(1, 'Realizada', 11.0, '2026-10-10T10:00:00'),
            ],
          };
        }
        if (p == '/api/visitas') {
          d = [vis(3, 'Programada', null, '2026-11-25T10:00:00'), vis(2, 'Realizada', 12.0, '2026-11-10T10:00:00')];
        }
        h.resolve(Response(requestOptions: o, statusCode: 200, data: d));
      },
    ),
  );
  return api;
}

Widget app(ApiClient api, Widget home) {
  final auth = AuthProvider(api);
  auth.sesion = Sesion(token: 't', expira: DateTime(2030), usuarioId: 'med1', nombre: 'Doc', rol: 'Medico');
  auth.estado = EstadoAuth.conSesion;
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: api),
      ChangeNotifierProvider.value(value: auth),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  testWidgets('pacientes', (t) async {
    await t.pumpWidget(app(fake(), const PacientesMedicoScreen()));
    await t.pumpAndSettle();
    await t.tap(find.text('Firulais'));
    await t.pumpAndSettle();
    expect(find.text('Cambiar técnico'), findsOneWidget);
  });
  testWidgets('crear', (t) async {
    await t.pumpWidget(app(fake(), const CrearPacienteScreen()));
    await t.pumpAndSettle();
    await t.tap(find.text('Especie'));
    await t.pumpAndSettle();
    await t.tap(find.text('Perro').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Raza'));
    await t.pumpAndSettle();
    expect(find.text('Labrador'), findsWidgets);
    await t.tap(find.text('Labrador').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Toca para buscar o crear el dueño'));
    await t.pumpAndSettle();
    expect(find.text('Sin resultados'), findsOneWidget);
  });
  testWidgets('historial', (t) async {
    await t.pumpWidget(app(fake(), const HistorialScreen(pacienteId: 1)));
    await t.pumpAndSettle();
    expect(find.text('Evolución del peso (kg)'), findsOneWidget);
    expect(find.text('3 visita(s) · 2 realizada(s)'), findsOneWidget);
  });
  testWidgets('actividades', (t) async {
    await t.pumpWidget(
      app(
        fake(),
        Builder(
          builder: (c) => ActividadesScreen(
            titulo: 'Act',
            cargarTecnicos: (ctx) => UsuariosRepository(ctx.read<ApiClient>()).tecnicosDeMedico('med1'),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Pendiente (1)'), findsOneWidget);
    await t.tap(find.text('Realizada (1)'));
    await t.pumpAndSettle();
    expect(find.textContaining('Control de peso'), findsOneWidget);
  });
}
