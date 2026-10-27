import re
from datetime import date, time
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from .config import ahora_ar


# los horarios siempre son en hora en punto, sin minutos
def _en_punto(t: time) -> time:
    if t.minute or t.second:
        raise ValueError("debe ser una hora en punto")
    return t


# lo que llega al crear o editar una sede
class SedeIn(BaseModel):
    nombre: str = Field(min_length=1, max_length=80)
    direccion: str = Field(min_length=1, max_length=120)
    hora_apertura: time = time(8, 0)
    hora_cierre: time = time(23, 0)

    @field_validator("hora_apertura", "hora_cierre")
    @classmethod
    def _horas_en_punto(cls, v: time) -> time:
        return _en_punto(v)

    # la apertura tiene que ser anterior al cierre
    @model_validator(mode="after")
    def _orden(self):
        if self.hora_apertura >= self.hora_cierre:
            raise ValueError("la apertura debe ser anterior al cierre")
        return self


# cantidad_canchas y deportes no son columnas, los calcula el router de catalogo
class SedeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    nombre: str
    direccion: str
    hora_apertura: time
    hora_cierre: time
    cantidad_canchas: int = 0
    deportes: list[str] = []


class DeporteIn(BaseModel):
    nombre: str = Field(min_length=1, max_length=40)


class DeporteOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    nombre: str


# datos de una cancha: precio mayor a 0 y numero desde 1
class EspacioIn(BaseModel):
    nombre: str = Field(min_length=1, max_length=120, description="Ej: Moron_Rivadavia_Futbol_F5_Cancha_1")
    sede_id: int
    deporte_id: int
    subtipo: Optional[str] = Field(default=None, max_length=40, description="Ej: Fútbol 5, Cemento, 9 Hoyos")
    numero: int = Field(default=1, ge=1)
    precio_hora: float = Field(gt=0)
    indoor: bool = False
    iluminada: bool = False
    hora_apertura: time = time(8, 0)
    hora_cierre: time = time(23, 0)

    @field_validator("hora_apertura", "hora_cierre")
    @classmethod
    def _horas_en_punto(cls, v: time) -> time:
        return _en_punto(v)

    # igual que en la sede, apertura antes que cierre
    @model_validator(mode="after")
    def _orden(self):
        if self.hora_apertura >= self.hora_cierre:
            raise ValueError("la apertura debe ser anterior al cierre")
        return self


class EspacioOut(BaseModel):
    id: int
    nombre: str
    numero: int
    subtipo: Optional[str] = None
    sede_id: int
    sede_nombre: str
    deporte_id: int
    deporte_nombre: str
    precio_hora: float
    indoor: bool
    iluminada: bool = False
    hora_apertura: time
    hora_cierre: time


# perfil nuevo: el dni tiene que tener 7 u 8 digitos y la fecha de nacimiento no puede ser futura. el mail se
# toma del token de firebase
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
    es_admin: bool = False


class FcmTokenIn(BaseModel):
    token: str = Field(min_length=10, max_length=300)


# la hora en punto y la duracion de 1 o 2 horas se controlan en el endpoint de reservas
class ReservaIn(BaseModel):
    espacio_id: int
    fecha: date
    hora_inicio: time = Field(description="Hora en punto, ej: 18:00")
    hora_fin: time = Field(description="Hora en punto, ej: 19:00")


# proxima es true si esta confirmada y todavia no termino, la app lo usa para separar proximas de historial
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
