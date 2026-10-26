# Club Jonatan Medrano – Backend (API REST)

API del sistema de reserva de espacios deportivos. Está hecha con **FastAPI** y **PostgreSQL**
(SQLAlchemy), usa **Firebase Authentication** para el login y **Firebase Cloud Messaging** para
las notificaciones push. La documentación interactiva (Swagger) queda en `/docs`.

- API en producción: https://club-jonatan-api.onrender.com  (Swagger: `/docs`, estado: `/health`)
- App móvil (Flutter): ver el `README.md` de la raíz del repositorio.
- Modelo de datos: `docs/MODELO_DE_DATOS.md`.

> El servicio gratuito de Render se duerme tras 15 minutos sin uso. La primera consulta puede
> tardar cerca de 1 minuto en responder; las siguientes son rápidas.

## Tecnologías
| Parte | Tecnología |
|---|---|
| Framework | FastAPI + Uvicorn |
| Base de datos | PostgreSQL + SQLAlchemy 2 (psycopg2) |
| Validación | Pydantic v2 |
| Login | Firebase Authentication (el servidor verifica el ID token) |
| Push | Firebase Cloud Messaging (firebase-admin) |
| Recordatorios | APScheduler (cada 5 minutos) |
| Despliegue | Render (`render.yaml`) |

## Estructura
```
backend/
├── app/
│   ├── main.py            # arranque, /health, manejo de errores, scheduler
│   ├── config.py          # variables de entorno
│   ├── database.py        # conexión
│   ├── models.py          # tablas
│   ├── schemas.py         # entradas/salidas de la API
│   ├── auth.py            # verificación del token, usuario actual, admin
│   ├── notifications.py   # push y recordatorios
│   ├── seed.py            # datos iniciales (4 sedes, 5 deportes, 22 canchas)
│   └── routers/           # catalogo, usuarios, reservas, admin
├── obtener_token.py       # ayuda para probar en Swagger
├── requirements.txt
└── .env.example
```

## Puesta en marcha local

**Requisitos:** Python 3.10 o superior, PostgreSQL, y un proyecto de Firebase con
Authentication (Email/Password) activado.

1. **Base de datos.** En pgAdmin o psql: `CREATE DATABASE club_db;`
2. **Credenciales de Firebase.** Consola de Firebase → Configuración del proyecto →
   *Cuentas de servicio* → *Generar nueva clave privada*. Guardá el archivo como
   `backend/firebase-credentials.json`.
3. **Configuración y dependencias** (PowerShell):
   ```powershell
   cd backend
   copy .env.example .env        # editá DATABASE_URL con tu contraseña de PostgreSQL
   python -m venv venv
   .\venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   ```
4. **Datos iniciales:** `python -m app.seed` (con `--reset` reemplaza el catálogo; conserva usuarios).
   Las tablas se crean solas al iniciar.
5. **Ejecutar:**
   ```powershell
   python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```
   Swagger en http://localhost:8000/docs

> **Seguridad:** `.env` y `firebase-credentials.json` están en `.gitignore`. No los subas a GitHub
> ni los compartas. Si se expusieran, generá una clave nueva en Firebase y cambiá las contraseñas.

### Variables de entorno
| Variable | Para qué sirve |
|---|---|
| `DATABASE_URL` | Conexión a PostgreSQL |
| `FIREBASE_CREDENTIALS_FILE` | Ruta al JSON de la cuenta de servicio (local) |
| `FIREBASE_CREDENTIALS_JSON` | El mismo JSON en una sola línea (Render) |
| `FIREBASE_WEB_API_KEY` | Solo para `obtener_token.py` |
| `ADMIN_EMAIL` | Correo del único administrador |
| `ENABLE_SCHEDULER` | `true` envía recordatorios automáticos |
| `AUTO_SEED` | `true` carga el catálogo si la base está vacía |

## Endpoints
**Públicos**

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/sedes` | Sedes con sus deportes y cantidad de canchas |
| GET | `/deportes` | Deportes |
| GET | `/espacios?sede_id=&deporte_id=` | Canchas, con filtros opcionales |
| GET | `/espacios/{id}/disponibilidad?fecha=AAAA-MM-DD` | Horarios libres y ocupados de un día |
| GET | `/health` | Estado del servicio |

**Con login** (header `Authorization: Bearer <ID token de Firebase>`)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/usuarios` | Crear mi perfil |
| GET / PUT / DELETE | `/usuarios/me` | Ver, editar o borrar mi cuenta |
| PUT | `/usuarios/me/fcm-token` | Registrar el dispositivo para push |
| POST | `/reservas` | Reservar una cancha |
| GET | `/reservas/mias` | Mis reservas (vigentes e historial) |
| PATCH | `/reservas/{id}/cancelar` | Cancelar una reserva |

**Administrador** (solo el correo de `ADMIN_EMAIL`; sección *Administración* en Swagger)

| Método | Ruta | Descripción |
|---|---|---|
| POST / PUT / DELETE | `/admin/sedes[/{id}]` | Alta, modificación y baja de sedes |
| POST / PUT / DELETE | `/admin/deportes[/{id}]` | Alta, modificación y baja de deportes |
| POST / PUT / DELETE | `/admin/espacios[/{id}]` | Alta, modificación y baja de canchas |
| GET | `/admin/usuarios` | Listar usuarios |
| GET | `/admin/reservas` | Listar todas las reservas |
| POST | `/admin/notificaciones/probar` | Enviarse una notificación de prueba |
| POST | `/admin/recordatorios/ejecutar` | Ejecutar ahora el chequeo de recordatorios |

Códigos de error usados: `400` datos inválidos, `401` sin login o token vencido, `403` no es admin,
`404` no existe, `409` conflicto (horario ocupado, nombre repetido, dependencias).

## Probar con login en Swagger
1. Registrá un usuario desde la app (el correo y la contraseña de la app, no los de Gmail).
2. En `.env` completá `FIREBASE_WEB_API_KEY` (Configuración del proyecto → General → *Clave de API web*).
3. Con el entorno virtual activo: `python obtener_token.py "correo" "contraseña"`.
4. Copiá el token que empieza con `eyJ` y en `/docs` tocá **Authorize** → pegalo **solo el token, sin la palabra Bearer**.
5. Dura 1 hora; pasado ese tiempo pedí otro.

## Reglas de negocio
- Reservas de **1 o 2 horas**, en **hora en punto**, dentro del horario de la cancha.
- No se puede reservar en el pasado (se usa la hora de Argentina).
- No puede haber dos reservas superpuestas en la misma cancha, ni dos de la misma persona en el mismo horario.
- Si dos personas reservan a la vez, entra una sola (bloqueo de fila en la base).
- Las reservas canceladas quedan en el historial con estado `cancelada`.
- El horario de una cancha debe estar dentro del de su sede; no se puede achicar el horario de una sede si hay canchas que quedarían por fuera.
- No se elimina una sede o deporte con canchas, ni una cancha con reservas.

## Notificaciones push
- Al **cancelar** una reserva se avisa al usuario.
- Cada 5 minutos un proceso envía **recordatorios 24 horas y 1 hora antes** (una sola vez cada uno).
- Para probar sin esperar: `POST /admin/notificaciones/probar` y `POST /admin/recordatorios/ejecutar`.

## Despliegue en Render
`render.yaml` (en la raíz del repositorio) crea la base y la API.
1. Subí el repo a GitHub.
2. En https://render.com: **New → Blueprint** → elegí el repositorio → *Apply*.
3. Completá `FIREBASE_CREDENTIALS_JSON` (JSON en una línea:
   `python -c "import json;print(json.dumps(json.load(open('firebase-credentials.json'))))" | clip`)
   y `ADMIN_EMAIL`.
4. Al terminar queda en `https://<nombre>.onrender.com`. Con `AUTO_SEED=true` se carga el catálogo si la base está vacía.

**Límites del plan gratuito**
- La API se duerme a los 15 minutos; mientras duerme no se envían recordatorios. Un monitor
  externo (por ejemplo UptimeRobot) consultando `/health` cada 5 minutos la mantiene despierta.
- La base gratuita **vence a los 30 días** de creada (14 días de gracia antes de borrarse).
- No hay consola (Shell) en el plan gratuito: por eso existe `AUTO_SEED`.
