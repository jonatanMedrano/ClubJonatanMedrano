from datetime import date, datetime, time
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from ..config import ahora_ar
from ..database import get_db
from ..models import Deporte, Espacio, Reserva, Sede
from ..schemas import DeporteOut, EspacioOut, SedeOut

router = APIRouter(tags=["Catálogo (sin login)"])


def espacio_a_dict(e: Espacio) -> dict:
    return {
        "id": e.id, "nombre": e.nombre, "numero": e.numero,
        "sede_id": e.sede_id, "sede_nombre": e.sede.nombre,
        "deporte_id": e.deporte_id, "deporte_nombre": e.deporte.nombre,
        "precio_hora": float(e.precio_hora), "indoor": e.indoor,
        "hora_apertura": e.hora_apertura, "hora_cierre": e.hora_cierre,
    }


@router.get("/sedes", response_model=list[SedeOut], summary="Listar sedes")
def listar_sedes(db: Session = Depends(get_db)):
    return db.scalars(select(Sede).order_by(Sede.id)).all()


@router.get("/deportes", response_model=list[DeporteOut], summary="Listar deportes")
def listar_deportes(db: Session = Depends(get_db)):
    return db.scalars(select(Deporte).order_by(Deporte.id)).all()


@router.get("/espacios", response_model=list[EspacioOut],
            summary="Listar canchas (filtrables por sede y deporte)")
def listar_espacios(
    sede_id: Optional[int] = None,
    deporte_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    q = select(Espacio).options(joinedload(Espacio.sede), joinedload(Espacio.deporte))
    if sede_id is not None:
        q = q.where(Espacio.sede_id == sede_id)
    if deporte_id is not None:
        q = q.where(Espacio.deporte_id == deporte_id)
    q = q.order_by(Espacio.sede_id, Espacio.deporte_id, Espacio.numero)
    return [espacio_a_dict(e) for e in db.scalars(q).all()]


@router.get("/espacios/{espacio_id}/disponibilidad",
            summary="Horarios de una cancha para una fecha")
def disponibilidad(espacio_id: int, fecha: date, db: Session = Depends(get_db)):
    espacio = db.get(Espacio, espacio_id)
    if espacio is None:
        raise HTTPException(404, "La cancha no existe.")
    reservas = db.scalars(
        select(Reserva).where(
            Reserva.espacio_id == espacio_id,
            Reserva.fecha == fecha,
            Reserva.estado == "confirmada",
        )
    ).all()
    ocupadas = {h for r in reservas for h in range(r.hora_inicio.hour, r.hora_fin.hour)}
    ahora = ahora_ar()
    horarios = []
    for h in range(espacio.hora_apertura.hour, espacio.hora_cierre.hour):
        pasado = datetime.combine(fecha, time(h)) <= ahora
        horarios.append({
            "hora_inicio": f"{h:02d}:00",
            "hora_fin": f"{h + 1:02d}:00",
            "disponible": (not pasado) and h not in ocupadas,
        })
    return {"espacio_id": espacio_id, "fecha": fecha, "horarios": horarios}
