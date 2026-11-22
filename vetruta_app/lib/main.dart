import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/navegacion.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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