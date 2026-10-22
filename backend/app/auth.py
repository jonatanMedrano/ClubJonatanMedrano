import json
import logging
import os
from typing import Optional

import firebase_admin
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth as fb_auth
from firebase_admin import credentials
from sqlalchemy import select
from sqlalchemy.orm import Session

from .database import get_db
from .models import Usuario

log = logging.getLogger("club")
bearer = HTTPBearer(auto_error=False)


def iniciar_firebase() -> bool:
    if firebase_admin._apps:
        return True
    contenido = os.getenv("FIREBASE_CREDENTIALS_JSON", "").strip()
    ruta = os.getenv("FIREBASE_CREDENTIALS_FILE", "").strip()
    try:
        if contenido:
            cred = credentials.Certificate(json.loads(contenido))
        elif ruta:
            cred = credentials.Certificate(ruta)
        else:
            log.warning("Firebase NO configurado: los endpoints con login van a fallar.")
            return False
        firebase_admin.initialize_app(cred)
        return True
    except Exception as e:  # noqa: BLE001
        log.error("No se pudo iniciar Firebase: %s", e)
        return False


def verificar_token(
    cred: Optional[HTTPAuthorizationCredentials] = Depends(bearer),
) -> dict:
    """Verifica contra Firebase el token que manda la app. Devuelve uid y email."""
    if cred is None:
        raise HTTPException(401, "Necesitás iniciar sesión.")
    if not firebase_admin._apps:
        raise HTTPException(503, "El servidor no tiene configurado Firebase.")
    try:
        return fb_auth.verify_id_token(cred.credentials, clock_skew_seconds=10)
    except Exception:  # noqa: BLE001
        raise HTTPException(401, "Sesión inválida o vencida. Volvé a iniciar sesión.")


def get_usuario_actual(
    token: dict = Depends(verificar_token), db: Session = Depends(get_db)
) -> Usuario:
    usuario = db.scalar(select(Usuario).where(Usuario.firebase_uid == token["uid"]))
    if usuario is None:
        raise HTTPException(404, "Todavía no completaste tu perfil.")
    return usuario
