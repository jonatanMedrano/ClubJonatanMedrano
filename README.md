# Club Jonatan Medrano – App de reserva de espacios deportivos

Aplicación Android hecha con **Flutter** para reservar canchas de distintos deportes en las sedes
del club. Se conecta a una **API REST** (FastAPI + PostgreSQL) publicada en **Render**, usa
**Firebase Authentication** para el login y **Firebase Cloud Messaging** para las notificaciones.

Trabajo práctico *Gestión de espacios deportivos* – Universidad de Morón, Electiva General.

| | |
|---|---|
| API en producción | https://club-jonatan-api.onrender.com |
| Documentación Swagger | https://club-jonatan-api.onrender.com/docs |
| Backend (README propio) | [`backend/README.md`](backend/README.md) |
| Modelo de datos | [`docs/MODELO_DE_DATOS.md`](docs/MODELO_DE_DATOS.md) |

## Qué hace la app
**Usuario**
- Registro, inicio de sesión y recuperación de contraseña (Firebase).
- Inicio con sedes y deportes; listado de sedes con su dirección, **horario** y deportes.
- Detalle de sede: canchas filtradas por deporte y tipo, con precio, horario, indoor/outdoor e iluminación.
- Reserva de 1 o 2 horas con calendario y grilla de horarios libres/ocupados, y pantalla de confirmación.
- Mis reservas (próximas e historial) con cancelación.
- Perfil: ver y editar datos, cambiar entre modo día, noche o automático, cerrar sesión y borrar la cuenta.
- Notificaciones push: aviso al cancelar y recordatorios 24 h y 1 h antes; bandeja de avisos dentro de la app.

**Administrador** (un único usuario, definido por `ADMIN_EMAIL` en el backend)
- Botón *Gestión admin* en el perfil: alta, modificación y baja de sedes, deportes y canchas.

La aplicación muestra mensajes claros ante errores de red, de sesión vencida o de datos inválidos.
Hay modo día (verde sobre blanco) y modo noche (negro con verde y blanco).

## Requisitos
- [Flutter](https://docs.flutter.dev/get-started/install) (canal estable) y Android Studio con un emulador (se probó con Pixel 6).
- Un proyecto de Firebase con Authentication (correo/contraseña) y Cloud Messaging.
- Para correr la API en tu PC: ver [`backend/README.md`](backend/README.md). Para usar la de Render no hace falta instalar nada más.

## Instalación
```powershell
git clone https://github.com/jonatanMedrano/ClubJonatanMedrano.git
cd ClubJonatanMedrano
flutter pub get
```

**Firebase.** Instalá la CLI y vinculá la app (genera `lib/firebase_options.dart` y
`android/app/google-services.json`):
```powershell
dart pub global activate flutterfire_cli
dart pub global run flutterfire_cli:flutterfire configure
```
Si `flutterfire` no se reconoce, agregá `%LOCALAPPDATA%\Pub\Cache\bin` al PATH o usá el comando de arriba.

**Permisos de Android** (`android/app/src/main/AndroidManifest.xml`): `INTERNET` y `POST_NOTIFICATIONS`.

## Ejecutar
La dirección de la API se define al compilar con `--dart-define=API_URL=...`
(por defecto `http://10.0.2.2:8000`, que es tu PC vista desde el emulador).

| Quiero usar | Comando |
|---|---|
| API en Render | `flutter run --dart-define=API_URL=https://club-jonatan-api.onrender.com` |
| API local | levantar `uvicorn` (ver backend) y `flutter run` |

En VS Code ya están las configuraciones **App -> API local (emulador)** y **App -> API en Render**
en `.vscode/launch.json` (menú *Run and Debug*).

La primera consulta a Render puede demorar cerca de 1 minuto si el servicio estaba dormido.

## Ícono de la app
Los archivos están en `assets/icon/`. Para generarlo en Android:
```powershell
flutter pub add --dev flutter_launcher_icons
```
Agregá esto al final de `pubspec.yaml` (sin sangría al inicio) y ejecutá `dart run flutter_launcher_icons`:
```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#0B0F0C"
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"
```

## Generar el APK
```powershell
flutter build apk --release --dart-define=API_URL=https://club-jonatan-api.onrender.com
```
El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Estructura del proyecto
```
lib/
├── main.dart                  # arranque, tema, sesión
├── core/                      # tema (día/noche), componentes visuales, errores, configuración
├── models/models.dart         # Sede, Deporte, Espacio, Reserva, Usuario
├── services/
│   ├── api_service.dart       # llamadas HTTP a la API
│   ├── stores.dart            # estado: usuario, catálogo, reservas, avisos
│   └── notification_service.dart  # Firebase Messaging
└── screens/                   # login, registro, inicio, sedes, detalle, reservar,
                               # mis reservas, perfil, notificaciones y gestión admin
backend/                       # API FastAPI (ver backend/README.md)
docs/                          # modelo de datos
assets/icon/                   # ícono de la app
render.yaml                    # despliegue en Render
```

## Seguridad
No se suben al repositorio `backend/.env` ni `backend/firebase-credentials.json`
(están en `.gitignore`). La app solo guarda la sesión de Firebase y la preferencia de tema.
