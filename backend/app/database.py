from sqlalchemy import create_engine, text
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from .config import DATABASE_URL

# pool_pre_ping prueba la conexion antes de usarla, evita errores cuando la base cierra conexiones inactivas
engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False)


class Base(DeclarativeBase):
    pass


# abre una sesion por pedido y la cierra siempre al terminar. la usan todos los endpoints con Depends
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def migrar_columnas() -> None:
    # create_all no agrega columnas a tablas que ya existen. estas dos se agregaron despues, por eso van con
    # alter table
    with engine.begin() as c:
        c.execute(text("ALTER TABLE espacios ADD COLUMN IF NOT EXISTS subtipo VARCHAR(40)"))
        c.execute(text("ALTER TABLE espacios ADD COLUMN IF NOT EXISTS iluminada BOOLEAN NOT NULL DEFAULT FALSE"))
