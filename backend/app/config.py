import os
from datetime import datetime
from zoneinfo import ZoneInfo

from dotenv import load_dotenv

load_dotenv()

# todas las comparaciones de fecha y hora usan la zona de argentina, el servidor de render esta en otra
TZ_AR = ZoneInfo("America/Argentina/Buenos_Aires")


# render entrega la url como postgres:// y sqlalchemy necesita saber el driver (psycopg2), por eso se cambia el
# prefijo
def _database_url() -> str:
    url = os.getenv("DATABASE_URL", "").strip()
    if not url:
        raise RuntimeError(
            "Falta DATABASE_URL. Copiá .env.example como .env y completalo."
        )
    # Render entrega postgres:// o postgresql://; SQLAlchemy necesita el driver.
    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+psycopg2://", 1)
    elif url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+psycopg2://", 1)
    return url


DATABASE_URL = _database_url()

# Unico usuario administrador: el correo con el que se registro en la app.
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "").strip().lower()


def ahora_ar() -> datetime:
    # hora de argentina sin zona, asi se puede comparar directo con la fecha y la hora de las reservas
    return datetime.now(TZ_AR).replace(tzinfo=None)
