# ClubJonatanMedrano – Backend (API REST)

API en **FastAPI** + **PostgreSQL** (SQLAlchemy) con login por **Firebase Authentication**
y notificaciones push por **Firebase Cloud Messaging**. Documentada con Swagger en `/docs`.

## Requisitos
- Python 3.10 o superior
- PostgreSQL instalado y una base creada (ej: `club_db`)
- Un proyecto de Firebase con Authentication (Email/Password) activado

## 1. Base de datos
En pgAdmin (o psql) creá la base:
```sql
CREATE DATABASE club_db;
```

## 2. Credenciales de Firebase
Consola de Firebase → ⚙ Configuración del proyecto → **Cuentas de servicio** →
**Generar nueva clave privada**. Guardá el JSON como `backend/firebase-credentials.json`
(está en `.gitignore`, **no se sube a GitHub**).

## 3. Configuración
```powershell
cd backend
copy .env.example .env     # y editá DATABASE_URL con tu contraseña de PostgreSQL
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## 4. Cargar datos iniciales (4 sedes, 5 deportes, 22 canchas)
```powershell
python -m app.seed
```
Las tablas se crean solas al iniciar la API o el seed. Editá `app/seed.py` para cambiar
direcciones, precios u horarios reales.

> Para reemplazar los datos por los del diseño: `python -m app.seed --reset`
> (borra reservas, canchas, sedes y deportes; los usuarios se conservan).

## 5. Ejecutar
```powershell
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
Swagger: http://localhost:8000/docs

## Probar endpoints con login en Swagger
1. Creá un usuario desde la app (o en Firebase → Authentication).
2. Poné `FIREBASE_WEB_API_KEY` en `.env` (Configuración del proyecto → General → *Clave de API web*).
3. `python obtener_token.py correo@ejemplo.com password` → copiá el token.
4. En `/docs` tocá **Authorize** y pegalo.

## Endpoints
| Método | Ruta | Login |
|---|---|---|
| GET | `/sedes`, `/deportes` | no |
| GET | `/espacios?sede_id=&deporte_id=` | no |
| GET | `/espacios/{id}/disponibilidad?fecha=AAAA-MM-DD` | no |
| POST | `/usuarios` (crear perfil) | sí |
| GET / PUT / DELETE | `/usuarios/me` | sí |
| PUT | `/usuarios/me/fcm-token` | sí |
| POST | `/reservas` | sí |
| GET | `/reservas/mias` | sí |
| PATCH | `/reservas/{id}/cancelar` | sí |

## Administrador
Hay un único administrador: el usuario cuyo correo está en `ADMIN_EMAIL` del `.env`.
Se registra normalmente desde la app y, desde ese momento, puede usar los endpoints
`/admin/...` (crear, modificar y eliminar sedes, deportes y canchas; ver usuarios y reservas).
En Swagger aparecen en la sección *Administración*.

## Reglas de reservas
1 o 2 horas, en hora en punto, dentro del horario de la cancha; no en el pasado
(hora de Argentina); sin superposición con otra reserva de la cancha ni propia;
si dos personas reservan a la vez, entra una sola (bloqueo de filas). Las canceladas
quedan en el historial con estado `cancelada`.

## Notificaciones push
Cada 5 minutos un job envía recordatorios 24 h y 1 h antes, y al cancelar se avisa al usuario.
Se desactivan con `ENABLE_SCHEDULER=false`.

## Despliegue en Render
El archivo `render.yaml` (en la raíz del repo) describe todo: la base PostgreSQL y la API.

1. Subí el repo a GitHub (`git push`). **No** subas `.env` ni `firebase-credentials.json`.
2. En https://render.com: **New → Blueprint** → elegí el repositorio → *Apply*.
3. Render pide dos valores:
   - `FIREBASE_CREDENTIALS_JSON`: el contenido del JSON en **una sola línea**
     (`python -c "import json;print(json.dumps(json.load(open('firebase-credentials.json'))))" | clip`).
   - `ADMIN_EMAIL`: el correo del usuario administrador.
4. Cuando termine, la API queda en `https://<nombre>.onrender.com` y Swagger en `/docs`.
   Con `AUTO_SEED=true` se cargan solas las sedes, deportes y canchas (solo si la base está vacía).

Variables de entorno: `DATABASE_URL`, `FIREBASE_CREDENTIALS_JSON`, `ADMIN_EMAIL`,
`ENABLE_SCHEDULER`, `AUTO_SEED`, `PYTHON_VERSION`.

### Limitaciones del plan gratuito
- La API se duerme tras 15 min sin uso y tarda ~1 minuto en despertar. Mientras duerme no
  se envían recordatorios: un monitor externo (UptimeRobot) que consulte `/health` cada
  5 minutos la mantiene despierta.
- La base gratuita **vence a los 30 días** de creada (14 días de gracia antes de borrarse).
- No hay Shell: por eso existe `AUTO_SEED`.
