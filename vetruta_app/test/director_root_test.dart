import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:vetruta_app/core/api_client.dart';
import 'package:vetruta_app/core/sesion.dart';
import 'package:vetruta_app/features/auth/auth_provider.dart';
import 'package:vetruta_app/features/director/actividades_director_screen.dart';
import 'package:vetruta_app/features/director/asignar_tecnicos_screen.dart';
import 'package:vetruta_app/features/root/crear_usuario_screen.dart';
import 'package:vetruta_app/features/root/usuarios_screen.dart';
import 'package:vetruta_app/features/tablero/tablero_screen.dart';

// Respuestas reales copiadas de Swagger.
final tablero = {
  'desde': '2026-11-01T00:00:00',
  'hasta': '2026-11-30T00:00:00',
  'resumen': {'programadas': 1, 'realizadas': 2, 'canceladas': 0, 'atrasadas': 0, 'porcentajeCumplimiento': 100},
  'porTecnico': [
    {'tecnicoId': 't1', 'tecnicoNombre': 'Aj Mosquito', 'realizadas': 1, 'vencidas': 0, 'porcentajeCumplimiento': 100},
    {'tecnicoId': 't2', 'tecnicoNombre': 'Ana gomez', 'realizadas': 1, 'vencidas': 0, 'porcentajeCumplimiento': 100},
  ],
  'porEspecie': [
    {'especie': 'Gato', 'total': 1},
    {'especie': 'Perro', 'total': 1},
  ],
};
final usuarios = [
  {
    'id': 't1',
    'email': 'ae@prueba.com',
    'nombreCompleto': 'Aj Mosquito',
    'rol': 'Tecnico',
    'activo': true,
    'zonaId': 1,
    'zonaNombre': 'Zona 1',
    'medicoId': 'm1',
    'medicoNombre': 'Ax Mosquito',
  },
  {
    'id': 't2',
    'email': 'tecnico2@vetruta.com',
    'nombreCompleto': 'Ana gomez',
    'rol': 'Tecnico',
    'activo': true,
    'zonaId': 1,
    'zonaNombre': 'Zona 1',
    'medicoId': null,
    'medicoNombre': null,
  },
  {
    'id': 'm1',
    'email': 'aj@prueba.com',
    'nombreCompleto': 'Ax Mosquito',
    'rol': 'Medico',
    'activo': true,
    'zonaId': 1,
    'zonaNombre': 'Zona 1',
    'medicoId': null,
    'medicoNombre': null,
  },
];

ApiClient fake() {
  final api = ApiClient();
  api.dio.interceptors.insert(
    0,
    InterceptorsWrapper(
      onRequest: (o, h) {
        dynamic d;
        if (o.path == '/api/tablero') d = tablero;
        if (o.path == '/api/usuarios') {
          final rol = o.queryParameters['rol'];
          d = usuarios.where((u) => rol == null || u['rol'] == rol).toList();
        }
        if (o.path == '/api/zonas') {
          d = [
            {'id': 1, 'nombre': 'Zona 1', 'activa': true},
          ];
        }
        h.resolve(Response(requestOptions: o, statusCode: 200, data: d));
      },
    ),
  );
  return api;
}

Widget app(Widget home, {String rol = 'Director'}) {
  final api = fake();
  final auth = AuthProvider(api)
    ..sesion = Sesion(token: 't', expira: DateTime(2030), usuarioId: 'yo', nombre: 'Yo', rol: rol)
    ..estado = EstadoAuth.conSesion;
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
  testWidgets('tablero', (t) async {
    await t.pumpWidget(app(const TableroScreen()));
    await t.pumpAndSettle();
    expect(find.text('100%'), findsWidgets);
    await t.scrollUntilVisible(find.text('Perro: 1'), 200);
    expect(find.text('Ana gomez'), findsOneWidget);
  });
  testWidgets('asignar', (t) async {
    await t.pumpWidget(app(const AsignarTecnicosScreen()));
    await t.pumpAndSettle();
    expect(find.textContaining('sin asignar'), findsOneWidget);
    await t.tap(find.text('Ana gomez'));
    await t.pumpAndSettle();
    expect(find.text('Ax Mosquito'), findsOneWidget);
  });
  testWidgets('personal', (t) async {
    await t.pumpWidget(app(const ActividadesDirectorScreen()));
    await t.tap(find.text('Personal'));
    await t.pumpAndSettle();
    expect(find.text('Técnicos sin médico'), findsOneWidget);
  });
  testWidgets('usuarios y crear', (t) async {
    await t.pumpWidget(app(const UsuariosScreen(), rol: 'Root'));
    await t.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNWidgets(3));
    await t.pumpWidget(app(const CrearUsuarioScreen(), rol: 'Root'));
    await t.pumpAndSettle();
    final boton = find.widgetWithText(FilledButton, 'Crear usuario');
    await t.ensureVisible(boton);
    await t.tap(boton);
    await t.pumpAndSettle();
    expect(find.text('Escribe el nombre'), findsOneWidget);
  });
}
