import logging
import os
from contextlib import asynccontextmanager

from apscheduler.schedulers.background import BackgroundScheduler
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .auth import iniciar_firebase
from .database import Base, engine
from .notifications import enviar_recordatorios
from .routers import catalogo, reservas, usuarios

logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    iniciar_firebase()
    Base.metadata.create_all(bind=engine)  # crea las tablas si no existen
    scheduler = None
    if os.getenv("ENABLE_SCHEDULER", "true").lower() == "true":
        scheduler = BackgroundScheduler(timezone="America/Argentina/Buenos_Aires")
        scheduler.add_job(enviar_recordatorios, "interval", minutes=5)
        scheduler.start()
    yield
    if scheduler:
        scheduler.shutdown(wait=False)


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


@app.exception_handler(RequestValidationError)
async def datos_invalidos(request: Request, exc: RequestValidationError):
    partes = []
    for e in exc.errors():
        campo = ".".join(str(x) for x in e["loc"] if x not in ("body", "query", "path"))
        partes.append(f"{campo} {_MENSAJES.get(e['type'], 'tiene un valor inválido')}")
    return JSONResponse(status_code=422, content={"detail": "Datos inválidos: " + "; ".join(partes)})


app.include_router(catalogo.router)
app.include_router(usuarios.router)
app.include_router(reservas.router)


@app.get("/", include_in_schema=False)
def raiz():
    return {"mensaje": "ClubJonatanMedrano API funcionando. Documentación en /docs"}
