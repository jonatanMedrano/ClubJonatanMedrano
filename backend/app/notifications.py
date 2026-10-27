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


# manda la notificacion por firebase cloud messaging. devuelve None si salio bien o el motivo del error, el
# endpoint de prueba lo usa para ver que fallo
def enviar_push_detalle(token: Optional[str], titulo: str, cuerpo: str) -> Optional[str]:
    # si no hay token es que el celular todavia no se registro
    if not token:
        return "El usuario todavía no registró un dispositivo."
    try:
        messaging.send(
            messaging.Message(
                notification=messaging.Notification(title=titulo, body=cuerpo),
                android=messaging.AndroidConfig(priority="high"),
                token=token,
            )
        )
        return None
    except Exception as e:  # noqa: BLE001
        log.warning("No se pudo enviar la notificación: %s", e)
        return f"{type(e).__name__}: {e}"


# lo mismo pero sin devolver nada: si falla solo queda en el log para no romper la accion del usuario
def enviar_push(token: Optional[str], titulo: str, cuerpo: str) -> None:
    # solo intenta enviar si hay token
    if token:
        enviar_push_detalle(token, titulo, cuerpo)


# la ejecuta apscheduler cada 5 minutos. busca reservas confirmadas de hoy a dos dias y avisa cuando faltan 24
# horas y cuando falta 1 hora. recordatorio_24h y recordatorio_1h se marcan al enviar para que no se repita
def enviar_recordatorios() -> None:
    ahora = ahora_ar()
    # sesion propia porque esto no corre dentro de un pedido de la api
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
            # cuanto falta para que empiece la reserva
            falta = datetime.combine(r.fecha, r.hora_inicio) - ahora
            hora = r.hora_inicio.strftime("%H:%M")
            # primero el aviso de 1 hora, y al mandarlo marco tambien el de 24 para que no salgan los dos
            if timedelta(0) < falta <= timedelta(hours=1) and not r.recordatorio_1h:
                enviar_push(r.usuario.fcm_token, "¡Tu reserva es en 1 hora!",
                            f"{r.espacio.nombre} a las {hora} hs.")
                r.recordatorio_1h = True
                r.recordatorio_24h = True
            elif timedelta(hours=1) < falta <= timedelta(hours=24) and not r.recordatorio_24h:
                cuando = "hoy" if r.fecha == ahora.date() else "mañana"
                enviar_push(r.usuario.fcm_token, "Recordatorio de reserva",
                            f"Tenés {r.espacio.nombre} {cuando} a las {hora} hs.")
                r.recordatorio_24h = True
        db.commit()
