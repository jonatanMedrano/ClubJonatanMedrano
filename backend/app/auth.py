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


# carga la credencial de la cuenta de servicio. en render viene como texto en una variable de entorno, en mi pc
# se lee del archivo json
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


# primer paso de cualquier endpoint con login: toma el token del header Authorization y le pide a firebase que
# lo valide. sin token o vencido responde 401
def verificar_token(
    cred: Optional[HTTPAuthorizationCredentials] = Depends(bearer),
) -> dict:
    # devuelve el contenido del token (uid, email) si firebase lo da por bueno
    if cred is None:
        raise HTTPException(401, "Necesitás iniciar sesión.")
    if not firebase_admin._apps:
        raise HTTPException(503, "El servidor no tiene configurado Firebase.")
    try:
        return fb_auth.verify_id_token(cred.credentials, clock_skew_seconds=10)
    except Exception:  # noqa: BLE001
        raise HTTPException(401, "Sesión inválida o vencida. Volvé a iniciar sesión.")


# segundo paso: con el uid que viene en el token busca el perfil en la base. si todavia no lo creo responde 404
def get_usuario_actual(
    token: dict = Depends(verificar_token), db: Session = Depends(get_db)
) -> Usuario:
    usuario = db.scalar(select(Usuario).where(Usuario.firebase_uid == token["uid"]))
    if usuario is None:
        raise HTTPException(404, "Todavía no completaste tu perfil.")
    return usuario


# tercer paso, solo para /admin: el admin es el usuario cuyo mail coincide con ADMIN_EMAIL, cualquier otro
# recibe 403
def get_admin(usuario: Usuario = Depends(get_usuario_actual)) -> Usuario:
    if not usuario.es_admin:
        raise HTTPException(403, "Solo el administrador puede realizar esta acción.")
    return usuario
