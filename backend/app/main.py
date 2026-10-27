import logging
import os
from contextlib import asynccontextmanager

from apscheduler.schedulers.background import BackgroundScheduler
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .auth import iniciar_firebase
from .database import Base, engine, migrar_columnas
from .notifications import enviar_recordatorios
from .routers import admin, catalogo, reservas, usuarios
from .seed import main as cargar_datos_iniciales

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("club")


# esto corre una vez cuando arranca la api y otra cuando se apaga. aca se prepara todo: firebase, las tablas,
# los datos iniciales y la tarea de recordatorios
@asynccontextmanager
async def lifespan(app: FastAPI):
    iniciar_firebase()
    Base.metadata.create_all(bind=engine)  # crea las tablas si no existen
    migrar_columnas()
    # En Render (plan gratis) no hay Shell para correr el seed a mano:
    # con AUTO_SEED=true carga sedes, deportes y canchas SOLO si la base esta vacia.
    if os.getenv("AUTO_SEED", "false").lower() == "true":
        try:
            cargar_datos_iniciales()
        except Exception:  # noqa: BLE001
            log.exception("No se pudieron cargar los datos iniciales")
    # la tarea de recordatorios corre en segundo plano dentro de este mismo proceso, por eso si render duerme la
    # api tampoco se mandan avisos
    scheduler = None
    if os.getenv("ENABLE_SCHEDULER", "true").lower() == "true":
        scheduler = BackgroundScheduler(timezone="America/Argentina/Buenos_Aires")
        scheduler.add_job(enviar_recordatorios, "interval", minutes=5)
        scheduler.start()
    yield
    if scheduler:
        scheduler.shutdown(wait=False)


# swagger sale solo en /docs a partir de los routers y los schemas
app = FastAPI(
    title="ClubJonatanMedrano API",
    description=(
        "API para reservar canchas deportivas.\n\n"
        "Los endpoints con candado necesitan el token de Firebase: "
        "tocá **Authorize** y pegá el ID token (se obtiene con `obtener_token.py`)."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# cors abierto para no tener problemas mientras desarrollo, en produccion habria que limitarlo al dominio real
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"],
                   allow_headers=["*"])

_MENSAJES = {
    "missing": "es obligatorio",
    "string_pattern_mismatch": "tiene un formato inválido",
    "string_too_short": "es demasiado corto",
    "string_too_long": "es demasiado largo",
    "date_parsing": "no es una fecha válida (AAAA-MM-DD)",
    "date_from_datetime_parsing": "no es una fecha válida (AAAA-MM-DD)",
    "time_parsing": "no es una hora válida (HH:MM)",
    "int_parsing": "debe ser un número",
}


# pydantic devuelve los errores en ingles y en formato lista. aca los junto en un solo mensaje en castellano
# para que la app lo muestre tal cual
@app.exception_handler(RequestValidationError)
async def datos_invalidos(request: Request, exc: RequestValidationError):
    partes = []
    for e in exc.errors():
        campo = ".".join(str(x) for x in e["loc"] if x not in ("body", "query", "path"))
        partes.append(f"{campo} {_MENSAJES.get(e['type'], 'tiene un valor inválido')}")
    return JSONResponse(status_code=422, content={"detail": "Datos inválidos: " + "; ".join(partes)})


# un router por tema: catalogo (publico), usuarios, reservas y admin
app.include_router(catalogo.router)
app.include_router(usuarios.router)
app.include_router(reservas.router)
app.include_router(admin.router)


@app.get("/health", include_in_schema=False)
def health():
    # lo usa render para saber que la api esta viva, y tambien un monitor externo para que no se duerma
    return {"status": "ok"}


@app.get("/", include_in_schema=False)
def raiz():
    return {"mensaje": "ClubJonatanMedrano API funcionando. Documentación en /docs"}
