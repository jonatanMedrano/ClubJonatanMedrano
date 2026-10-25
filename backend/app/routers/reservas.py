from datetime import datetime, timedelta

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from ..auth import get_usuario_actual
from ..config import ahora_ar
from ..database import get_db
from ..models import Espacio, Reserva, Usuario
from ..notifications import enviar_push
from ..schemas import ReservaIn, ReservaOut

router = APIRouter(prefix="/reservas", tags=["Reservas (con login)"])


def reserva_a_dict(r: Reserva) -> dict:
    return {
        "id": r.id, "espacio_id": r.espacio_id,
        "espacio_nombre": r.espacio.nombre, "sede_nombre": r.espacio.sede.nombre,
        "fecha": r.fecha, "hora_inicio": r.hora_inicio, "hora_fin": r.hora_fin,
        "total": float(r.total), "estado": r.estado,
        "proxima": r.estado == "confirmada" and datetime.combine(r.fecha, r.hora_fin) > ahora_ar(),
    }


def _cargar(db: Session, reserva_id: int) -> Reserva:
    return db.scalars(
        select(Reserva)
        .options(joinedload(Reserva.espacio).joinedload(Espacio.sede))
        .where(Reserva.id == reserva_id)
    ).one()


@router.post("", response_model=ReservaOut, status_code=201, summary="Reservar una cancha")
def crear_reserva(data: ReservaIn, usuario: Usuario = Depends(get_usuario_actual),
                  db: Session = Depends(get_db)):
    ini, fin = data.hora_inicio, data.hora_fin

    if ini.minute or ini.second or fin.minute or fin.second:
        raise HTTPException(400, "Los horarios deben empezar y terminar en hora en punto (ej: 18:00).")
    horas = fin.hour - ini.hour
    if horas not in (1, 2):
        raise HTTPException(400, "La reserva debe durar 1 o 2 horas.")

    # Bloqueamos al usuario y luego a la cancha: si dos personas reservan lo mismo
    # a la vez, la segunda espera y después ve el horario ocupado. Entra solo una.
    db.execute(select(Usuario.id).where(Usuario.id == usuario.id).with_for_update())
    espacio = db.scalars(
        select(Espacio).where(Espacio.id == data.espacio_id).with_for_update()
    ).one_or_none()
    if espacio is None:
        raise HTTPException(404, "La cancha no existe.")

    if ini < espacio.hora_apertura or fin > espacio.hora_cierre:
        raise HTTPException(
            400,
            f"La cancha funciona de {espacio.hora_apertura:%H:%M} a {espacio.hora_cierre:%H:%M} hs.",
        )

    ahora = ahora_ar()
    inicio_dt = datetime.combine(data.fecha, ini)
    if inicio_dt <= ahora:
        raise HTTPException(400, "No se puede reservar en un horario pasado.")

    solapa = (Reserva.estado == "confirmada", Reserva.fecha == data.fecha,
              Reserva.hora_inicio < fin, Reserva.hora_fin > ini)
    if db.scalar(select(Reserva.id).where(Reserva.espacio_id == espacio.id, *solapa).limit(1)):
        raise HTTPException(409, "Ese horario ya está ocupado.")
    if db.scalar(select(Reserva.id).where(Reserva.usuario_id == usuario.id, *solapa).limit(1)):
        raise HTTPException(409, "Ya tenés otra reserva en ese horario.")

    falta = inicio_dt - ahora
    reserva = Reserva(
        usuario_id=usuario.id, espacio_id=espacio.id, fecha=data.fecha,
        hora_inicio=ini, hora_fin=fin, total=espacio.precio_hora * horas,
        estado="confirmada",
        # Si se reserva con poca anticipación, no mandamos recordatorios que ya pasaron.
        recordatorio_24h=falta <= timedelta(hours=24),
        recordatorio_1h=falta <= timedelta(hours=1),
    )
    db.add(reserva)
    db.commit()
    return reserva_a_dict(_cargar(db, reserva.id))


@router.get("/mias", response_model=list[ReservaOut],
            summary="Mis reservas (próximas e historial)")
def mis_reservas(usuario: Usuario = Depends(get_usuario_actual),
                 db: Session = Depends(get_db)):
    reservas = db.scalars(
        select(Reserva)
        .options(joinedload(Reserva.espacio).joinedload(Espacio.sede))
        .where(Reserva.usuario_id == usuario.id)
        .order_by(Reserva.fecha.desc(), Reserva.hora_inicio.desc())
    ).all()
    return [reserva_a_dict(r) for r in reservas]


@router.patch("/{reserva_id}/cancelar", response_model=ReservaOut,
              summary="Cancelar una reserva")
def cancelar_reserva(reserva_id: int, bg: BackgroundTasks,
                     usuario: Usuario = Depends(get_usuario_actual),
                     db: Session = Depends(get_db)):
    r = db.scalars(
        select(Reserva).where(Reserva.id == reserva_id, Reserva.usuario_id == usuario.id)
    ).one_or_none()
    if r is None:
        raise HTTPException(404, "La reserva no existe.")
    if r.estado == "cancelada":
        raise HTTPException(409, "La reserva ya estaba cancelada.")
    if datetime.combine(r.fecha, r.hora_fin) <= ahora_ar():
        raise HTTPException(400, "No se puede cancelar una reserva que ya finalizó.")
    r.estado = "cancelada"  # no se borra: queda en el historial
    db.commit()
    res = _cargar(db, r.id)
    bg.add_task(enviar_push, usuario.fcm_token, "Reserva cancelada",
                f"Cancelaste {res.espacio.nombre} el {r.fecha:%d/%m} a las {r.hora_inicio:%H:%M} hs.")
    return reserva_a_dict(res)
