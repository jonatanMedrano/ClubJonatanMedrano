import os
from datetime import datetime
from zoneinfo import ZoneInfo

from dotenv import load_dotenv

load_dotenv()

TZ_AR = ZoneInfo("America/Argentina/Buenos_Aires")


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


def ahora_ar() -> datetime:
    """Hora actual de Argentina, sin zona (para comparar con fecha/hora de reservas)."""
    return datetime.now(TZ_AR).replace(tzinfo=None)
