from sqlalchemy import create_engine, text
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from .config import DATABASE_URL

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def migrar_columnas() -> None:
    """Agrega columnas nuevas a tablas ya existentes (create_all no lo hace)."""
    with engine.begin() as c:
        c.execute(text("ALTER TABLE espacios ADD COLUMN IF NOT EXISTS subtipo VARCHAR(40)"))
        c.execute(text("ALTER TABLE espacios ADD COLUMN IF NOT EXISTS iluminada BOOLEAN NOT NULL DEFAULT FALSE"))
