import logging

from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import auth as fb_auth
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..auth import get_usuario_actual, verificar_token
from ..database import get_db
from ..models import Usuario
from ..schemas import FcmTokenIn, UsuarioIn, UsuarioOut, UsuarioUpdate

log = logging.getLogger("club")
router = APIRouter(prefix="/usuarios", tags=["Usuarios (con login)"])


@router.post("", response_model=UsuarioOut, status_code=201, summary="Crear mi perfil")
def crear_perfil(data: UsuarioIn, token: dict = Depends(verificar_token),
                 db: Session = Depends(get_db)):
    if db.scalar(select(Usuario).where(Usuario.firebase_uid == token["uid"])):
        raise HTTPException(409, "Ya tenés un perfil creado.")
    if db.scalar(select(Usuario).where(Usuario.dni == data.dni)):
        raise HTTPException(409, "Ese DNI ya está registrado.")
    email = token.get("email") or data.email
    if not email:
        raise HTTPException(400, "No se pudo determinar tu correo.")
    if db.scalar(select(Usuario).where(Usuario.email == email)):
        raise HTTPException(409, "Ese correo ya está registrado.")
    usuario = Usuario(firebase_uid=token["uid"], nombre=data.nombre,
                      apellido=data.apellido, dni=data.dni,
                      fecha_nacimiento=data.fecha_nacimiento, email=email)
    db.add(usuario)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "El DNI o el correo ya están registrados.")
    db.refresh(usuario)
    return usuario


@router.get("/me", response_model=UsuarioOut, summary="Ver mi perfil")
def ver_perfil(usuario: Usuario = Depends(get_usuario_actual)):
    return usuario


@router.put("/me", response_model=UsuarioOut, summary="Editar mi perfil")
def editar_perfil(data: UsuarioUpdate, usuario: Usuario = Depends(get_usuario_actual),
                  db: Session = Depends(get_db)):
    for campo, valor in data.model_dump(exclude_none=True).items():
        setattr(usuario, campo, valor.strip() if isinstance(valor, str) else valor)
    db.commit()
    db.refresh(usuario)
    return usuario


@router.put("/me/fcm-token", status_code=204, summary="Guardar token de notificaciones")
def guardar_fcm_token(data: FcmTokenIn, usuario: Usuario = Depends(get_usuario_actual),
                      db: Session = Depends(get_db)):
    # Un dispositivo pertenece a un solo usuario a la vez.
    db.execute(update(Usuario).where(Usuario.fcm_token == data.token,
                                     Usuario.id != usuario.id).values(fcm_token=None))
    usuario.fcm_token = data.token
    db.commit()


@router.delete("/me", status_code=204, summary="Borrar mi cuenta")
def borrar_cuenta(usuario: Usuario = Depends(get_usuario_actual),
                  db: Session = Depends(get_db)):
    uid = usuario.firebase_uid
    db.delete(usuario)  # también borra sus reservas
    db.commit()
    try:
        fb_auth.delete_user(uid)
    except Exception as e:  # noqa: BLE001
        log.warning("No se pudo borrar el usuario de Firebase: %s", e)
