from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from ..auth import get_admin
from ..database import get_db
from ..models import Deporte, Espacio, Reserva, Sede, Usuario
from ..notifications import enviar_push_detalle, enviar_recordatorios
from ..schemas import (DeporteIn, DeporteOut, EspacioIn, EspacioOut, SedeIn,
                       SedeOut, UsuarioOut)
from .catalogo import espacio_a_dict
from .reservas import reserva_a_dict

router = APIRouter(prefix="/admin", tags=["Administración (solo admin)"],
                   dependencies=[Depends(get_admin)])


def _guardar(db: Session, mensaje_duplicado: str) -> None:
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, mensaje_duplicado)


def _obtener(db: Session, modelo, id_: int, nombre: str):
    obj = db.get(modelo, id_)
    if obj is None:
        raise HTTPException(404, f"{nombre} no existe.")
    return obj


# ---------------- Sedes ----------------
@router.post("/sedes", response_model=SedeOut, status_code=201, summary="Crear sede")
def crear_sede(data: SedeIn, db: Session = Depends(get_db)):
    sede = Sede(**data.model_dump())
    db.add(sede)
    _guardar(db, "Ya existe una sede con ese nombre.")
    db.refresh(sede)
    return sede


@router.put("/sedes/{sede_id}", response_model=SedeOut, summary="Modificar sede")
def modificar_sede(sede_id: int, data: SedeIn, db: Session = Depends(get_db)):
    sede = _obtener(db, Sede, sede_id, "La sede")
    # No se puede achicar el horario de la sede dejando canchas por fuera.
    fuera = db.scalar(
        select(Espacio.id)
        .where(Espacio.sede_id == sede_id,
               or_(Espacio.hora_apertura < data.hora_apertura,
                   Espacio.hora_cierre > data.hora_cierre))
        .limit(1)
    )
    if fuera is not None:
        raise HTTPException(
            409,
            "Hay canchas con horarios fuera del nuevo horario de la sede. Ajustalas primero.",
        )
    for k, v in data.model_dump().items():
        setattr(sede, k, v)
    _guardar(db, "Ya existe una sede con ese nombre.")
    db.refresh(sede)
    return sede


@router.delete("/sedes/{sede_id}", status_code=204, summary="Eliminar sede")
def eliminar_sede(sede_id: int, db: Session = Depends(get_db)):
    sede = _obtener(db, Sede, sede_id, "La sede")
    if db.scalar(select(Espacio.id).where(Espacio.sede_id == sede_id).limit(1)):
        raise HTTPException(409, "La sede tiene canchas. Eliminalas o movelas primero.")
    db.delete(sede)
    db.commit()


# ---------------- Deportes ----------------
@router.post("/deportes", response_model=DeporteOut, status_code=201, summary="Crear deporte")
def crear_deporte(data: DeporteIn, db: Session = Depends(get_db)):
    dep = Deporte(nombre=data.nombre.strip())
    db.add(dep)
    _guardar(db, "Ya existe un deporte con ese nombre.")
    db.refresh(dep)
    return dep


@router.put("/deportes/{deporte_id}", response_model=DeporteOut, summary="Modificar deporte")
def modificar_deporte(deporte_id: int, data: DeporteIn, db: Session = Depends(get_db)):
    dep = _obtener(db, Deporte, deporte_id, "El deporte")
    dep.nombre = data.nombre.strip()
    _guardar(db, "Ya existe un deporte con ese nombre.")
    db.refresh(dep)
    return dep


@router.delete("/deportes/{deporte_id}", status_code=204, summary="Eliminar deporte")
def eliminar_deporte(deporte_id: int, db: Session = Depends(get_db)):
    dep = _obtener(db, Deporte, deporte_id, "El deporte")
    if db.scalar(select(Espacio.id).where(Espacio.deporte_id == deporte_id).limit(1)):
        raise HTTPException(409, "El deporte tiene canchas asociadas.")
    db.delete(dep)
    db.commit()


# ---------------- Canchas ----------------
def _aplicar_espacio(e: Espacio, data: EspacioIn, db: Session) -> None:
    sede = _obtener(db, Sede, data.sede_id, "La sede")
    _obtener(db, Deporte, data.deporte_id, "El deporte")
    # Los horarios de una cancha tienen que estar dentro de los de su sede.
    if data.hora_apertura < sede.hora_apertura or data.hora_cierre > sede.hora_cierre:
        raise HTTPException(
            400,
            f"El horario de la cancha debe estar dentro del de la sede "
            f"({sede.hora_apertura:%H:%M} a {sede.hora_cierre:%H:%M}).",
        )
    for k, v in data.model_dump().items():
        setattr(e, k, Decimal(str(v)) if k == "precio_hora" else v)


def _espacio_out(db: Session, id_: int) -> dict:
    e = db.scalars(select(Espacio).options(joinedload(Espacio.sede), joinedload(Espacio.deporte))
                   .where(Espacio.id == id_)).one()
    return espacio_a_dict(e)


@router.post("/espacios", response_model=EspacioOut, status_code=201, summary="Crear cancha")
def crear_espacio(data: EspacioIn, db: Session = Depends(get_db)):
    e = Espacio()
    _aplicar_espacio(e, data, db)
    db.add(e)
    _guardar(db, "Ya existe una cancha con ese nombre.")
    return _espacio_out(db, e.id)


@router.put("/espacios/{espacio_id}", response_model=EspacioOut, summary="Modificar cancha")
def modificar_espacio(espacio_id: int, data: EspacioIn, db: Session = Depends(get_db)):
    e = _obtener(db, Espacio, espacio_id, "La cancha")
    _aplicar_espacio(e, data, db)
    _guardar(db, "Ya existe una cancha con ese nombre.")
    return _espacio_out(db, e.id)


@router.delete("/espacios/{espacio_id}", status_code=204, summary="Eliminar cancha")
def eliminar_espacio(espacio_id: int, db: Session = Depends(get_db)):
    e = _obtener(db, Espacio, espacio_id, "La cancha")
    if db.scalar(select(Reserva.id).where(Reserva.espacio_id == espacio_id).limit(1)):
        raise HTTPException(409, "La cancha tiene reservas asociadas y no se puede eliminar.")
    db.delete(e)
    db.commit()


# ---------------- Consultas ----------------
@router.get("/usuarios", response_model=list[UsuarioOut], summary="Listar usuarios")
def listar_usuarios(db: Session = Depends(get_db)):
    return db.scalars(select(Usuario).order_by(Usuario.id)).all()


@router.get("/reservas", summary="Listar todas las reservas")
def listar_reservas(db: Session = Depends(get_db)):
    reservas = db.scalars(
        select(Reserva)
        .options(joinedload(Reserva.espacio).joinedload(Espacio.sede), joinedload(Reserva.usuario))
        .order_by(Reserva.fecha.desc(), Reserva.hora_inicio.desc())
    ).all()
    return [{**reserva_a_dict(r), "usuario": f"{r.usuario.nombre} {r.usuario.apellido}",
             "usuario_email": r.usuario.email} for r in reservas]


# ---------------- Pruebas de notificaciones ----------------
@router.post("/notificaciones/probar",
             summary="Enviar una notificación de prueba a mi propio celular")
def probar_notificacion(admin: Usuario = Depends(get_admin)):
    error = enviar_push_detalle(
        admin.fcm_token, "Notificación de prueba",
        "Si ves esto, las notificaciones push funcionan.")
    if error:
        raise HTTPException(502, f"No se pudo enviar la notificación. {error}")
    return {"enviada": True}


@router.post("/recordatorios/ejecutar",
             summary="Ejecutar ahora el aviso de recordatorios (sin esperar 5 minutos)")
def ejecutar_recordatorios():
    enviar_recordatorios()
    return {"mensaje": "Recordatorios procesados."}
