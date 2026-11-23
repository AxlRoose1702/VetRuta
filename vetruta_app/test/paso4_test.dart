import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:vetruta_app/core/api_client.dart';
import 'package:vetruta_app/features/auth/auth_provider.dart';
import 'package:vetruta_app/features/tecnico/mis_pacientes_screen.dart';
import 'package:vetruta_app/features/visitas/programar_visita_screen.dart';

final paciente = {
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
  'tecnicoNombre': 'T',
  'fotoUrl': null,
  'latitud': null,
  'longitud': null,
};
final paciente2 = {...paciente, 'id': 2, 'nombre': 'Michi'};
final visita = {
  'id': 1,
  'pacienteId': 1,
  'pacienteNombre': 'Firulais',
  'especieNombre': 'Perro',
  'duenoNombre': 'Juan',
  'servicioId': 1,
  'servicioNombre': 'Vacunación',
  'tecnicoId': 'abc',
  'tecnicoNombre': 'T',
  'fechaProgramada': '2026-11-20T10:00:00',
  'estado': 'Programada',
  'atrasada': true,
  'fechaRegistro': null,
  'pesoKg': null,
  'alturaCm': null,
  'temperatura': null,
  'condicion': null,
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
        dynamic data;
        if (o.path == '/api/pacientes') data = [paciente, paciente2];
        if (o.path == '/api/visitas') data = [visita];
        if (o.path == '/api/servicios') {
          data = [
            {'id': 1, 'nombre': 'Vacunación', 'precio': 150.0, 'duracionMinutos': 30},
          ];
        }
        h.resolve(Response(requestOptions: o, statusCode: 200, data: data));
      },
    ),
  );
  return api;
}

Widget app(ApiClient api, Widget home) => MultiProvider(
  providers: [
    Provider<ApiClient>.value(value: api),
    ChangeNotifierProvider(create: (_) => AuthProvider(api)),
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

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  testWidgets('mis pacientes', (tester) async {
    await tester.pumpWidget(app(fake(), const MisPacientesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Firulais (Perro)'), findsOneWidget);
    expect(find.textContaining('1 sin visita programada'), findsOneWidget);
    expect(find.textContaining('ATRASADA'), findsOneWidget);
  });
  testWidgets('programar', (tester) async {
    await tester.pumpWidget(app(fake(), const ProgramarVisitaScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servicio'));
    await tester.pumpAndSettle();
    expect(find.text('Vacunación · Q150.00 · 30 min'), findsWidgets);
    await tester.tap(find.text('Vacunación · Q150.00 · 30 min').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fecha y hora'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
