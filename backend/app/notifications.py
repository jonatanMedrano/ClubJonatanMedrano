import logging
from typing import Optional
from datetime import datetime, timedelta

from firebase_admin import messaging
from sqlalchemy import select
from sqlalchemy.orm import joinedload

from .config import ahora_ar
from .database import SessionLocal
from .models import Reserva

log = logging.getLogger("club")


def enviar_push(token: Optional[str], titulo: str, cuerpo: str) -> None:
    if not token:
        return
    try:
        messaging.send(
            messaging.Message(
                notification=messaging.Notification(title=titulo, body=cuerpo),
                android=messaging.AndroidConfig(priority="high"),
                token=token,
            )
        )
    except Exception as e:  # noqa: BLE001
        log.warning("No se pudo enviar la notificación: %s", e)


def enviar_recordatorios() -> None:
    """Corre cada 5 min: avisa 24 h y 1 h antes de cada reserva confirmada."""
    ahora = ahora_ar()
    with SessionLocal() as db:
        reservas = db.scalars(
            select(Reserva)
            .options(joinedload(Reserva.usuario), joinedload(Reserva.espacio))
            .where(
                Reserva.estado == "confirmada",
                Reserva.fecha >= ahora.date(),
                Reserva.fecha <= ahora.date() + timedelta(days=2),
            )
        ).all()
        for r in reservas:
            falta = datetime.combine(r.fecha, r.hora_inicio) - ahora
            hora = r.hora_inicio.strftime("%H:%M")
            if timedelta(0) < falta <= timedelta(hours=1) and not r.recordatorio_1h:
                enviar_push(r.usuario.fcm_token, "¡Tu reserva es en 1 hora!",
                            f"{r.espacio.nombre} a las {hora} hs.")
                r.recordatorio_1h = True
                r.recordatorio_24h = True
            elif timedelta(hours=1) < falta <= timedelta(hours=24) and not r.recordatorio_24h:
                enviar_push(r.usuario.fcm_token, "Recordatorio de reserva",
                            f"Mañana tenés {r.espacio.nombre} a las {hora} hs.")
                r.recordatorio_24h = True
        db.commit()
