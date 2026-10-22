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

## Reglas de reservas
1 o 2 horas, en hora en punto, dentro del horario de la cancha; no en el pasado
(hora de Argentina); sin superposición con otra reserva de la cancha ni propia;
si dos personas reservan a la vez, entra una sola (bloqueo de filas). Las canceladas
quedan en el historial con estado `cancelada`.

## Notificaciones push
Cada 5 minutos un job envía recordatorios 24 h y 1 h antes, y al cancelar se avisa al usuario.
Se desactivan con `ENABLE_SCHEDULER=false`.

## Despliegue en Render
1. **New → PostgreSQL**: copiá la *Internal Database URL*.
2. **New → Web Service** (repo de GitHub, *Root Directory* = `backend`):
   - Build: `pip install -r requirements.txt`
   - Start: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
3. Variables de entorno: `DATABASE_URL`, `FIREBASE_CREDENTIALS_JSON` (pegá TODO el contenido
   del JSON), `ENABLE_SCHEDULER=true`.
4. Una vez desplegado, desde el *Shell* de Render corré `python -m app.seed`.

> En el plan gratuito Render duerme el servicio tras 15 min sin uso, y mientras duerme
> no se envían recordatorios.
