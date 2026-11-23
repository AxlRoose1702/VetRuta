# VetRuta — App Flutter (Android)

App móvil de VetRuta: atención veterinaria a domicilio con cuatro roles (Root, Director, Médico y Técnico). Consume la API .NET de este mismo repositorio (`src/VetRuta.Api`).

## Requisitos

- Flutter 3.50 (Dart 3.14) — `flutter doctor` sin errores para Android.
- Android SDK y un emulador o teléfono Android con **Google Play** (para Google Maps).
- La API corriendo (ver el README principal) con la base de datos creada.
- Una llave de **Google Maps** con *Maps SDK for Android* habilitado.

## Configuración

1. **URL de la API.** En `lib/core/config.dart`, `apiUrl` apunta a `http://10.0.2.2:<puerto>`. `10.0.2.2` es la PC vista desde el emulador; el puerto es el del perfil `http` de `src/VetRuta.Api/Properties/launchSettings.json`. También se puede cambiar sin tocar código:
   ```
   flutter run --dart-define=API_URL=http://10.0.2.2:5000
   ```
   En un teléfono real usa la IP de la PC en la red local.
2. **Llave de Google Maps.** Agrega esta línea a `android/local.properties` (ese archivo no se sube a Git):
   ```
   MAPS_API_KEY=tu_llave
   ```
   `android/app/build.gradle.kts` la lee y la pone en el `AndroidManifest.xml` con `manifestPlaceholders`.
3. **API en http.** Corre la API con el perfil `http`. El emulador no confía en el certificado de desarrollo https; por eso el manifest tiene `usesCleartextTraffic="true"` (solo para desarrollo).

## Ejecutar

```
cd vetruta_app
flutter pub get
flutter run
```

Pruebas automáticas (widgets con la API simulada):

```
flutter test
```

Usuario inicial: `root@vetruta.com` / `Root123!`. Con él se crean los demás usuarios desde la app (menú **Usuarios**).

## Qué hace cada rol

| Rol | Pantallas |
|---|---|
| Root | Usuarios: lista con filtro por rol, activar/desactivar, crear usuario (rol y zona) |
| Director | Asignar técnicos a médicos (asignar, reasignar, quitar); Actividades de todo el personal (personal, pacientes, visitas); Tablero |
| Médico | Pacientes (crear con dueño, especie → raza, foto, técnico; cambiar técnico; historial con gráfica de peso); Programar visita; Actividades de sus técnicos; Tablero |
| Técnico | Calendario de visitas por estado; Registrar visita (peso, altura, temperatura, condición corporal, observaciones, GPS y foto); Mapa de Google Maps; Mis pacientes; Programar visita; Tablero |

El menú se arma con el rol del token. La API también valida el rol y la jerarquía en cada endpoint, así que la regla está en la app y en el backend.

## Arquitectura

```
lib/
├── core/       Configuración, cliente HTTP (Dio + token + 401), sesión, fechas
├── data/
│   ├── models/        Modelos de las respuestas de la API
│   └── repositories/  Una clase por recurso de la API (visitas, pacientes, usuarios, catálogos, tablero)
├── shared/     Widgets comunes (estado, foto, avatar)
└── features/   Una carpeta por módulo: auth, home, tecnico, visitas, pacientes, medico, director, root, tablero
```

- **Gestor de estado:** `provider` con `ChangeNotifier` (`AuthProvider`, `CalendarioProvider`, `PacientesTecnicoProvider`).
- **HTTP:** `dio`. Un interceptor agrega `Authorization: Bearer <token>` y, si la API responde 401, cierra la sesión y vuelve al login.
- **Sesión:** el JWT se guarda cifrado con `flutter_secure_storage`. Al abrir la app se valida con `GET /api/auth/me`.
- **Paquetes:** `table_calendar` (calendario), `google_maps_flutter` (mapa), `image_picker` (cámara y galería), `geolocator` (GPS), `fl_chart` (gráficas), `intl` y `flutter_localizations` (español).

## Decisiones tomadas

- **Estados de la visita.** La API manda `estado` (Programada, Realizada, Cancelada) y `atrasada`. La app muestra los tres del enunciado: **pendiente** (amarillo), **realizada** (verde) y **atrasada** (rojo). Las **canceladas** se muestran en gris, porque el enunciado no las menciona.
- **Estado del paciente en el mapa.** La API no tiene ese campo, así que la app cruza `/api/pacientes` con `/api/visitas`: rojo = tiene una visita atrasada, amarillo = tiene una pendiente, celeste = sin visita programada, verde = al día. Los pacientes sin ubicación se listan aparte; su ubicación se guarda al registrar la primera visita.
- **Condición corporal** como escala de 1 a 9 (la API recibe texto).
- **Fotos** reducidas a 1600 px y calidad 80 para no pasar de 5 MB; solo JPG o PNG, igual que la API.
- **Fechas.** Se mandan en UTC y se muestran en la hora del teléfono.
- **Import de Material.** Flutter 3.50 sugiere `package:material_ui`, pero `table_calendar` usa `package:flutter/material.dart`; mezclar las dos rompe el calendario, así que la app usa `flutter/material.dart` y el aviso de obsoleto se apaga en `analysis_options.yaml`.
- **Reprogramar y cancelar visitas** (solo Médico en la API) no tienen pantalla: el enunciado no lo pide.
