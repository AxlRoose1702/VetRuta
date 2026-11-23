import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:vetruta_app/core/api_client.dart';
import 'package:vetruta_app/data/models/visita.dart';
import 'package:vetruta_app/features/auth/auth_provider.dart';
import 'package:vetruta_app/features/visitas/detalle_visita_screen.dart';
import 'package:vetruta_app/features/visitas/registrar_visita_screen.dart';

final datos = {
  'id': 1,
  'pacienteId': 1,
  'pacienteNombre': 'Firulais',
  'especieNombre': 'Perro',
  'duenoNombre': 'Juan',
  'servicioId': 1,
  'servicioNombre': 'Vacunación',
  'tecnicoId': 'abc',
  'tecnicoNombre': 'T',
  'fechaProgramada': '2026-11-22T10:00:00',
  'estado': 'Realizada',
  'atrasada': false,
  'fechaRegistro': '2026-11-22T11:00:00',
  'pesoKg': 12.5,
  'alturaCm': 45,
  'temperatura': 38.5,
  'condicion': '5 - Ideal',
  'latitud': 14.6,
  'longitud': -90.5,
  'fotoUrl': null,
  'observaciones': 'ok',
};

void main() {
  testWidgets('detalle', (tester) async {
    await initializeDateFormatting('es');
    final api = ApiClient();
    api.dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (o, h) => h.resolve(Response(requestOptions: o, statusCode: 200, data: datos)),
      ),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ],
        child: const MaterialApp(home: DetalleVisitaScreen(visitaId: 1)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Visita registrada'), findsOneWidget);
  });
  testWidgets('registrar', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider<ApiClient>.value(value: ApiClient())],
        child: MaterialApp(home: RegistrarVisitaScreen(visita: Visita.fromJson({...datos, 'estado': 'Programada'}))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(find.text('Guardar registro'), find.byType(ListView), const Offset(0, -300));
    await tester.tap(find.text('Guardar registro'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(find.text('Escribe el peso'), find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el peso'), findsOneWidget);
  });
}
