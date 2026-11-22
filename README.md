# VetRuta

Sistema para una clínica veterinaria a domicilio. Este repositorio contiene la **API en .NET 9** con **SQL Server**. La app móvil en Flutter se agrega en la carpeta `app/` (ver la sección [App Flutter](#app-flutter)).

La API valida la identidad con **JWT**, aplica los **roles** (Root, Director, Médico, Técnico) y la **jerarquía** (cada jefe ve solo a su gente) en cada operación, y guarda el **historial completo** de visitas.

---

## Contenido

1. [Requisitos](#requisitos)
2. [Estructura del proyecto](#estructura-del-proyecto)
3. [Configuración](#configuración)
4. [Base de datos](#base-de-datos)
5. [Ejecutar la API](#ejecutar-la-api)
6. [Probar con Swagger y autenticarse](#probar-con-swagger-y-autenticarse)
7. [Endpoints por rol](#endpoints-por-rol)
8. [Reglas de negocio y decisiones de diseño](#reglas-de-negocio-y-decisiones-de-diseño)
9. [Fotos](#fotos)
10. [Ramas de Git](#ramas-de-git)
11. [App Flutter](#app-flutter)

---

## Requisitos

| Herramienta | Versión | Para qué |
|---|---|---|
| .NET SDK | **9.0** (probado con 9.0.320) | Compilar y correr la API |
| SQL Server | **Express** 2019 o superior, instancia `.\SQLEXPRESS` | Base de datos |
| dotnet-ef | **9.0.x** | Migraciones y script SQL |
| SQL Server Management Studio (opcional) | Cualquiera reciente | Ver las tablas y correr el script |
| Visual Studio 2022 o VS Code (opcional) | | Editar y depurar |

Instalar la herramienta de migraciones (si ya tienes otra versión, desinstálala primero):

```powershell
dotnet tool uninstall -g dotnet-ef
dotnet tool install -g dotnet-ef --version 9.0.*
dotnet ef --version
```

El archivo `global.json` fija el SDK 9, para que no se use otro SDK instalado (por ejemplo .NET 10 u 11).

> **Por qué .NET 9:** la prueba pide .NET 8 o superior. Se usó .NET 9 porque Visual Studio 2022 lo soporta completo.

---

## Estructura del proyecto

```
VetRuta/
├── global.json                    SDK 9 fijo
├── VetRuta.sln
├── database/
│   └── VetRuta.sql                Script de creación de la base de datos
└── src/
    ├── VetRuta.Domain/            Entidades y reglas puras (no depende de nadie)
    │   ├── Entities/              Zona, Especie, Raza, Servicio, Dueno, Paciente, Visita, EstadoVisita
    │   └── Roles.cs               Nombres de los 4 roles
    ├── VetRuta.Application/       Capa de aplicación (reservada para lógica de casos de uso)
    ├── VetRuta.Infrastructure/    Acceso a datos
    │   ├── Identity/ApplicationUser.cs   Usuario con NombreCompleto, Activo, MedicoId, ZonaId
    │   ├── Data/AppDbContext.cs          EF Core + Identity + configuración Fluent API
    │   ├── Data/DbSeeder.cs              Roles, usuario Root y catálogos iniciales
    │   └── Migrations/                   Migraciones de EF Core
    └── VetRuta.Api/               Web API
        ├── Controllers/           Auth, Usuarios, Zonas, Especies, Razas, Servicios,
        │                          Duenos, Pacientes, Visitas, Tablero
        ├── Dtos/                  Objetos de entrada y salida de la API
        ├── Services/TokenService.cs      Genera el JWT
        ├── Settings/JwtSettings.cs       Lee la sección "Jwt" del appsettings
        ├── wwwroot/fotos/         Fotos de las visitas (se crea sola)
        ├── appsettings.json
        └── Program.cs             Registro de servicios y pipeline
```

Las referencias van en un solo sentido: `Api → Infrastructure → Application → Domain`. El dominio no conoce la base de datos ni ASP.NET.

---

## Configuración

`src/VetRuta.Api/appsettings.json`:

```json
{
  "ConnectionStrings": {
    "Default": "Server=.\\SQLEXPRESS;Database=VetRuta;Trusted_Connection=True;TrustServerCertificate=True"
  },
  "Jwt": {
    "Key": "una-clave-larga-de-al-menos-32-caracteres!!",
    "Issuer": "VetRuta",
    "Audience": "VetRuta",
    "ExpiraMinutos": 480
  }
}
```

- **Cadena de conexión:** usa autenticación de Windows (`Trusted_Connection=True`). Si tu instancia tiene otro nombre, cambia `.\\SQLEXPRESS` (por ejemplo `localhost` o `(localdb)\\MSSQLLocalDB`). Si usas usuario y contraseña de SQL, cambia `Trusted_Connection=True` por `User Id=...;Password=...`.
- **Jwt:Key:** debe tener al menos 32 caracteres. En producción iría en una variable de entorno o en *user secrets*, no en el repositorio.
- **ExpiraMinutos:** duración del token (480 = 8 horas, una jornada de trabajo).

---

## Base de datos

Hay dos formas de crearla. Usa **una** de las dos.

### Opción A: automática con la API (la más fácil)

Al arrancar, la API ejecuta `DbSeeder.SeedAsync`, que llama a `Database.MigrateAsync()`. Si la base `VetRuta` no existe, la crea y aplica todas las migraciones. Solo corre la API (siguiente sección).

También puedes aplicar las migraciones a mano, desde la carpeta raíz `VetRuta`:

```powershell
dotnet ef database update -p src/VetRuta.Infrastructure -s src/VetRuta.Api
```

### Opción B: con el script SQL `database/VetRuta.sql`

1. En SSMS, conéctate a `.\SQLEXPRESS` con **Autenticación de Windows** (marca *Confiar en el certificado del servidor*).
2. Crea la base vacía:
   ```sql
   CREATE DATABASE VetRuta;
   ```
3. Abre `database/VetRuta.sql`, elige la base **VetRuta** en el desplegable de arriba y presiona **Ejecutar** (F5).

O desde PowerShell con `sqlcmd`:

```powershell
sqlcmd -S .\SQLEXPRESS -E -Q "CREATE DATABASE VetRuta"
sqlcmd -S .\SQLEXPRESS -E -d VetRuta -i database\VetRuta.sql
```

El script es **idempotente**: se puede correr más de una vez sin errores, porque cada migración revisa la tabla `__EFMigrationsHistory` antes de aplicarse.

> El script crea **solo el esquema** (tablas, llaves, índices). Los roles, el usuario Root y los catálogos los crea la API la primera vez que arranca, porque la contraseña del Root se guarda con el hash de ASP.NET Identity y no se puede escribir a mano en SQL.

### Regenerar el script

Si cambia alguna entidad, crea la migración y vuelve a generar el script desde la carpeta raíz:

```powershell
dotnet ef migrations add NombreDelCambio -p src/VetRuta.Infrastructure -s src/VetRuta.Api
dotnet ef database update -p src/VetRuta.Infrastructure -s src/VetRuta.Api
dotnet ef migrations script --idempotent -p src/VetRuta.Infrastructure -s src/VetRuta.Api -o database/VetRuta.sql
```

### Datos iniciales (seed)

| Dato | Valor |
|---|---|
| Roles | Root, Director, Medico, Tecnico |
| Usuario Root | correo `root@vetruta.com`, contraseña `Root123!` |
| Zonas | Zona 1, Zona 10, Mixco |
| Especies y razas | Perro (Labrador, Pastor Alemán, Mestizo), Gato (Siamés, Persa, Mestizo), Ave (Perico, Canario), Conejo (Holland Lop, Rex), Reptil (Iguana, Tortuga) |
| Servicios | Control de peso (Q75, 20 min), Vacunación (Q150, 30 min), Desparasitación (Q100, 20 min), Curación de heridas (Q200, 45 min), Control postoperatorio (Q250, 40 min) |

El seed solo inserta lo que falta, así que reiniciar la API no duplica datos.

---

## Ejecutar la API

Desde la carpeta raíz `VetRuta`:

```powershell
dotnet restore
dotnet build
dotnet run --project src/VetRuta.Api --launch-profile https
```

En Visual Studio: abre `VetRuta.sln`, elige `VetRuta.Api` como proyecto de inicio y presiona **F5** con el perfil `https`.

La API queda en `https://localhost:7262` (el puerto está en `src/VetRuta.Api/Properties/launchSettings.json`). Si el navegador avisa del certificado, corre una vez `dotnet dev-certs https --trust`.

La raíz `/` responde 404 a propósito: la API no tiene página de inicio. Usa Swagger.

---

## Probar con Swagger y autenticarse

1. Abre `https://localhost:7262/swagger` (Swagger solo se activa en el entorno *Development*).
2. Busca `POST /api/auth/login`, presiona **Try it out** y manda:
   ```json
   { "email": "root@vetruta.com", "password": "Root123!" }
   ```
3. La respuesta trae `token`, `expira`, `usuarioId`, `nombre` y `rol`. Copia el `token`.
4. Presiona **Authorize** (arriba a la derecha), pega el token **sin** la palabra `Bearer` y acepta.
5. Llama `GET /api/auth/me`: debe devolver tu nombre y el rol Root.

Desde la app o Postman, manda el token en cada petición:

```
Authorization: Bearer <token>
```

Respuestas que vas a ver:

| Código | Significado |
|---|---|
| 200 / 201 / 204 | Correcto (201 al crear, con la URL del nuevo registro; 204 al editar o borrar) |
| 400 | Datos inválidos. El cuerpo trae `{ "mensaje": "..." }` |
| 401 | Sin token, token vencido o credenciales incorrectas |
| 403 | Tu rol no tiene permiso para esa acción |
| 404 | No existe **o no te corresponde** por jerarquía |
| 409 | Conflicto: duplicado, registro en uso o visita ya registrada |

### Flujo de prueba sugerido

1. Como **Root**: crea un Director, un Médico y dos Técnicos (`POST /api/usuarios`), uno con `medicoId` del médico.
2. Como **Director**: asigna el otro técnico al médico (`PUT /api/usuarios/{id}/medico`).
3. Como **Médico**: crea un dueño (`POST /api/duenos`) y un paciente asignado a su técnico (`POST /api/pacientes`), y prográmale una visita (`POST /api/visitas`).
4. Como **Técnico**: ve sus visitas (`GET /api/visitas`) y registra una con foto (`POST /api/visitas/{id}/registro`, formulario multipart). Intenta registrarla otra vez: responde 409.
5. Como cada rol: abre `GET /api/tablero` y `GET /api/pacientes/{id}/historial`, y revisa que cada uno vea solo lo suyo.

---

## Endpoints por rol

"Todos" significa cualquier usuario con token. En los endpoints marcados con **(J)** la respuesta además se filtra por jerarquía: el Técnico ve lo suyo, el Médico lo de sus técnicos, y Director y Root ven todo.

### Autenticación — `api/auth`

| Método y ruta | Quién | Qué hace |
|---|---|---|
| `POST /api/auth/login` | Público | Valida correo y contraseña y devuelve el JWT. Rechaza usuarios desactivados |
| `GET /api/auth/me` | Todos | Datos del usuario dueño del token |

### Usuarios — `api/usuarios`

| Método y ruta | Quién | Qué hace |
|---|---|---|
| `GET /api/usuarios?rol=&activo=` | Root, Director | Lista usuarios. El Director no ve a los Root |
| `GET /api/usuarios/{id}` | Root, Director | Un usuario |
| `GET /api/usuarios/medicos/{medicoId}/tecnicos` | Root, Director, Médico | Técnicos de un médico. Un médico solo puede pedir los suyos |
| `POST /api/usuarios` | Root | Crea un usuario de cualquier rol |
| `PUT /api/usuarios/{id}` | Root | Edita correo, nombre y zona |
| `PUT /api/usuarios/{id}/medico` | Root, Director | Asigna (o reasigna) un técnico a un médico |
| `DELETE /api/usuarios/{id}/medico` | Root, Director | Quita el médico a un técnico |
| `PATCH /api/usuarios/{id}/activar` · `/desactivar` | Root | Activa o desactiva. No puedes cambiar tu propio estado |
| `PUT /api/usuarios/{id}/password` | Root | Cambia la contraseña de un usuario |

### Catálogos — `api/zonas`, `api/especies`, `api/razas`, `api/servicios`

| Método y ruta | Quién | Qué hace |
|---|---|---|
| `GET` (lista y por id) | Todos | Leer catálogos |
| `GET /api/especies/{id}/razas` | Todos | Razas de una especie (para el combo de la app) |
| `GET /api/razas?especieId=` | Todos | Razas, filtrables por especie |
| `GET /api/zonas/{id}/tecnicos` | Root, Director, Médico | Técnicos de una zona |
| `POST`, `PUT` | Root, Director | Crear y editar |
| `DELETE` especies, razas, servicios | Root, Director | Borrar solo si nadie lo usa (si no, 409) |
| `PATCH /api/zonas/{id}/activar` · `/desactivar` | Root, Director | Las zonas no se borran, se desactivan |

### Dueños — `api/duenos`

| Método y ruta | Quién | Qué hace |
|---|---|---|
| `GET /api/duenos?buscar=` | Todos | Lista y busca por nombre o teléfono |
| `GET /api/duenos/{id}` | Todos | Un dueño con su total de pacientes |
| `POST`, `PUT /api/duenos/{id}` | Todos | Crear y editar |
| `DELETE /api/duenos/{id}` | Root, Director | Solo si no tiene pacientes |

### Pacientes — `api/pacientes`

| Método y ruta | Quién | Qué hace |
|---|---|---|
| `GET /api/pacientes?buscar=&especieId=&duenoId=&tecnicoId=` | Todos **(J)** | Lista con raza, especie, dueño y técnico |
| `GET /api/pacientes/{id}` | Todos **(J)** | Un paciente |
| `GET /api/pacientes/{id}/historial` | Todos **(J)** | Todas sus visitas, de la más reciente a la más vieja, con totales |
| `POST /api/pacientes` | Todos **(J)** | Crear. El técnico queda asignado a sí mismo; el médico debe elegir uno de sus técnicos |
| `PUT /api/pacientes/{id}` | Todos **(J)** | Editar datos (no cambia el técnico) |
| `PUT /api/pacientes/{id}/tecnico` | Root, Director, Médico **(J)** | Reasignar a otro técnico |
| `DELETE /api/pacientes/{id}` | Root, Director | Solo si no tiene visitas |

### Visitas — `api/visitas`

| Método y ruta | Quién | Qué hace |
|---|---|---|
| `GET /api/visitas?desde=&hasta=&estado=&atrasadas=&tecnicoId=&pacienteId=` | Todos **(J)** | Calendario y actividades: pendientes, realizadas, canceladas y atrasadas |
| `GET /api/visitas/{id}` | Todos **(J)** | Una visita |
| `POST /api/visitas` | Root, Director, Médico **(J)** | Programar. El técnico se toma del paciente |
| `PUT /api/visitas/{id}/fecha` | Root, Director, Médico **(J)** | Reprogramar, solo si sigue Programada |
| `PUT /api/visitas/{id}/cancelar` | Root, Director, Médico **(J)** | Cancelar, solo si sigue Programada |
| `POST /api/visitas/{id}/registro` | Técnico dueño de la visita | Registrar peso, altura, temperatura, condición, ubicación y foto (multipart/form-data). Después queda de solo lectura |

### Tablero — `api/tablero`

| Método y ruta | Quién | Qué hace |
|---|---|---|
| `GET /api/tablero?desde=&hasta=` | Todos **(J)** | Realizadas contra programadas, cumplimiento por técnico y pacientes por especie. Por defecto, el mes actual |

---

## Reglas de negocio y decisiones de diseño

El enunciado deja algunos puntos abiertos. Estas son las decisiones tomadas:

- **Identity + JWT propio.** Se usa ASP.NET Core Identity para guardar usuarios, contraseñas (con hash) y roles, y un endpoint de login propio que emite un JWT con el id, el nombre y el rol. No se usa `MapIdentityApi` porque no incluye los roles en el token.
- **Jerarquía en la misma tabla de usuarios.** El técnico tiene `MedicoId` (una relación de la tabla consigo misma). Como es un solo campo, un técnico pertenece a **un solo médico a la vez**; reasignarlo reemplaza el anterior. El médico puede tener técnicos en varias zonas porque la zona es del técnico, no del médico.
- **La jerarquía se aplica en la consulta.** Cada controller parte de un filtro (`PacientesVisibles`, `VisitasVisibles`) según el rol del token. Si algo no te corresponde, la API responde **404**, como si no existiera, para no revelar datos de otros.
- **DTOs.** La API nunca devuelve entidades. Recibe `...Request` y devuelve `...Response`, así no expone campos de Identity como `PasswordHash` y la app recibe datos listos (por ejemplo, el nombre de la especie además del id).
- **Sin borrados en cascada (`Restrict`).** Borrar un dueño con pacientes, un paciente con visitas o un catálogo en uso está prohibido en la base y en la API (409). Así el historial nunca se pierde.
- **Usuarios y zonas no se borran, se desactivan.** Un usuario desactivado no puede iniciar sesión, pero sus visitas siguen en el historial.
- **Visita registrada = solo lectura.** Una vez en estado `Realizada`, ningún endpoint la modifica. Cada visita es un registro nuevo, así se ve la evolución del paciente (por ejemplo, su peso).
- **"Atrasada" se calcula, no se guarda.** Es una visita `Programada` cuya fecha ya pasó. Como cambia sola con el tiempo, guardarla daría datos viejos.
- **Cumplimiento** = realizadas / (realizadas + programadas ya vencidas). Las canceladas y las programadas a futuro no cuentan, porque todavía no se pueden cumplir.
- **Fechas en UTC.** La API compara con `DateTime.UtcNow`. La app debe mandar las fechas en UTC (con `Z` al final).
- **Enums como texto.** El estado de la visita viaja como `"Programada"`, `"Realizada"` o `"Cancelada"`, no como número.
- **Fotos en disco.** Ver la sección siguiente.

---

## Fotos

- Se suben en `POST /api/visitas/{id}/registro` como `multipart/form-data`, campo `foto`.
- Solo JPG o PNG, máximo 5 MB.
- Se guardan en `src/VetRuta.Api/wwwroot/fotos/` con un nombre único (`visita-{id}-{guid}.jpg`). En la base solo queda la ruta, por ejemplo `/fotos/visita-3-ab12....jpg`.
- Se ven en el navegador en `https://localhost:7262/fotos/...` gracias a `app.UseStaticFiles()`.
- La carpeta se crea sola si no existe. Las fotos de prueba no deberían subirse al repositorio.

---

## Ramas de Git

- `main`: versión entregable.
- `develop`: integración.
- `feature/...`: una rama por funcionalidad, que se une a `develop` y luego a `main`.

---

## App Flutter

_Pendiente: requisitos (Flutter SDK, Android SDK, llave de Google Maps), cómo apuntar la app a la URL de la API y cómo correrla en un emulador o dispositivo Android._

Nota para el emulador de Android: `localhost` del emulador no es tu PC. Usa `https://10.0.2.2:7262` o el perfil `http` de la API.
