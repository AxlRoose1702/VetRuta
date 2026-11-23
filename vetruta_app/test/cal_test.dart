import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetruta_app/core/api_client.dart';
import 'package:vetruta_app/features/tecnico/calendario_screen.dart';

void main() {
  testWidgets('calendario', (tester) async {
    await initializeDateFormatting('es');
    final api = ApiClient();
    api.dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (o, h) {
          final hoy = DateTime.now().toUtc();
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: 200,
              data: [
                {
                  'id': 1,
                  'pacienteId': 1,
                  'pacienteNombre': 'Firulais',
                  'especieNombre': 'Perro',
                  'duenoNombre': 'Juan',
                  'servicioId': 1,
                  'servicioNombre': 'Vacunación',
                  'tecnicoId': 'abc',
                  'tecnicoNombre': 'T',
                  'fechaProgramada': '${hoy.toIso8601String().replaceAll('Z', '')}1',
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
                },
              ],
            ),
          );
        },
      ),
    );
    await tester.pumpWidget(
      Provider<ApiClient>.value(
        value: api,
        child: const MaterialApp(home: CalendarioScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Firulais (Perro)'), findsOneWidget);
  });
}
