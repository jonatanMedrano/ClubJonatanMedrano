import re
from datetime import date, time
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from .config import ahora_ar


class SedeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    nombre: str
    direccion: str
    hora_apertura: time
    hora_cierre: time


class DeporteOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    nombre: str


class EspacioOut(BaseModel):
    id: int
    nombre: str
    numero: int
    sede_id: int
    sede_nombre: str
    deporte_id: int
    deporte_nombre: str
    precio_hora: float
    indoor: bool
    hora_apertura: time
    hora_cierre: time


class UsuarioIn(BaseModel):
    nombre: str = Field(min_length=1, max_length=80)
    apellido: str = Field(min_length=1, max_length=80)
    dni: str = Field(pattern=r"^\d{7,8}$", description="7 u 8 dígitos")
    fecha_nacimiento: date
    email: Optional[str] = Field(default=None, description="Se toma del token de Firebase")

    @field_validator("nombre", "apellido")
    @classmethod
    def _limpiar(cls, v: str) -> str:
        v = re.sub(r"\s+", " ", v).strip()
        if not v:
            raise ValueError("vacío")
        return v

    @field_validator("fecha_nacimiento")
    @classmethod
    def _no_futura(cls, v: date) -> date:
        if v >= ahora_ar().date():
            raise ValueError("fecha futura")
        return v


class UsuarioUpdate(BaseModel):
    nombre: Optional[str] = Field(default=None, min_length=1, max_length=80)
    apellido: Optional[str] = Field(default=None, min_length=1, max_length=80)
    fecha_nacimiento: Optional[date] = None

    @field_validator("fecha_nacimiento")
    @classmethod
    def _no_futura(cls, v):
        if v is not None and v >= ahora_ar().date():
            raise ValueError("fecha futura")
        return v


class UsuarioOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    nombre: str
    apellido: str
    dni: str
    fecha_nacimiento: date
    email: str


class FcmTokenIn(BaseModel):
    token: str = Field(min_length=10, max_length=300)


class ReservaIn(BaseModel):
    espacio_id: int
    fecha: date
    hora_inicio: time = Field(description="Hora en punto, ej: 18:00")
    hora_fin: time = Field(description="Hora en punto, ej: 19:00")


class ReservaOut(BaseModel):
    id: int
    espacio_id: int
    espacio_nombre: str
    sede_nombre: str
    fecha: date
    hora_inicio: time
    hora_fin: time
    total: float
    estado: str
    proxima: bool = False
