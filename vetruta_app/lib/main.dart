import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/navegacion.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es'); // nombres de meses y días en español
  final api = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthProvider(api)..restaurarSesion()),
      ],
      child: const VetRutaApp(),
    ),
  );
}

class VetRutaApp extends StatelessWidget {
  const VetRutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VetRuta',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      // Calendarios y relojes (showDatePicker, showTimePicker) en español.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Según el estado de la sesión se muestra el login o el menú.
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          switch (auth.estado) {
            case EstadoAuth.cargando:
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            case EstadoAuth.sinSesion:
              return const LoginScreen();
            case EstadoAuth.conSesion:
              return const HomeScreen();
          }
        },
      ),
    );
  }
}
