from datetime import date, datetime, time
from decimal import Decimal
from typing import Optional

from sqlalchemy import (Boolean, Date, DateTime, ForeignKey, Index, Numeric,
                        String, Time, func)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .config import ADMIN_EMAIL
from .database import Base


# sede del club. tiene un horario general y las canchas tienen que quedar dentro de ese horario
class Sede(Base):
    __tablename__ = "sedes"
    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(80), unique=True)
    direccion: Mapped[str] = mapped_column(String(120))
    hora_apertura: Mapped[time] = mapped_column(Time, default=time(8, 0))
    hora_cierre: Mapped[time] = mapped_column(Time, default=time(23, 0))
    espacios: Mapped[list["Espacio"]] = relationship(back_populates="sede")


# catalogo de deportes: futbol, tenis, hockey, voley y golf
class Deporte(Base):
    __tablename__ = "deportes"
    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(40), unique=True)
    espacios: Mapped[list["Espacio"]] = relationship(back_populates="deporte")


# una cancha. pertenece a una sede y a un deporte, y guarda el precio por hora y su propio horario
class Espacio(Base):
    __tablename__ = "espacios"
    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(120), unique=True)
    numero: Mapped[int]
    precio_hora: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    indoor: Mapped[bool] = mapped_column(Boolean, default=False)
    iluminada: Mapped[bool] = mapped_column(Boolean, default=False)
    subtipo: Mapped[Optional[str]] = mapped_column(String(40), nullable=True)
    hora_apertura: Mapped[time] = mapped_column(Time)
    hora_cierre: Mapped[time] = mapped_column(Time)
    sede_id: Mapped[int] = mapped_column(ForeignKey("sedes.id"))
    deporte_id: Mapped[int] = mapped_column(ForeignKey("deportes.id"))
    sede: Mapped[Sede] = relationship(back_populates="espacios")
    deporte: Mapped[Deporte] = relationship(back_populates="espacios")
    reservas: Mapped[list["Reserva"]] = relationship(back_populates="espacio")


# perfil del usuario. la clave no se guarda aca, la maneja firebase y se vincula con firebase_uid
class Usuario(Base):
    __tablename__ = "usuarios"
    id: Mapped[int] = mapped_column(primary_key=True)
    firebase_uid: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    nombre: Mapped[str] = mapped_column(String(80))
    apellido: Mapped[str] = mapped_column(String(80))
    dni: Mapped[str] = mapped_column(String(8), unique=True)
    fecha_nacimiento: Mapped[date] = mapped_column(Date)
    email: Mapped[str] = mapped_column(String(160), unique=True)
    fcm_token: Mapped[Optional[str]] = mapped_column(String(300), nullable=True)
    # si se borra el usuario se borran tambien sus reservas (cascade)
    reservas: Mapped[list["Reserva"]] = relationship(
        back_populates="usuario", cascade="all, delete-orphan"
    )

    # no hay una columna de rol, es admin quien tenga el mismo mail que ADMIN_EMAIL
    @property
    def es_admin(self) -> bool:
        return bool(ADMIN_EMAIL) and self.email.lower() == ADMIN_EMAIL


# estado puede ser confirmada o cancelada, las canceladas no se borran para conservar el historial. el total se
# guarda al reservar, asi si despues cambia el precio de la cancha las reservas viejas quedan igual
class Reserva(Base):
    __tablename__ = "reservas"
    # indice para buscar rapido las reservas de una cancha en un dia, lo usan la disponibilidad y el control de
    # superposicion
    __table_args__ = (Index("ix_reservas_espacio_fecha", "espacio_id", "fecha"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    usuario_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id"), index=True)
    espacio_id: Mapped[int] = mapped_column(ForeignKey("espacios.id"))
    fecha: Mapped[date] = mapped_column(Date)
    hora_inicio: Mapped[time] = mapped_column(Time)
    hora_fin: Mapped[time] = mapped_column(Time)
    total: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    estado: Mapped[str] = mapped_column(String(20), default="confirmada")  # confirmada | cancelada
    creada_en: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    # marcas para no mandar dos veces el mismo recordatorio
    recordatorio_24h: Mapped[bool] = mapped_column(Boolean, default=False)
    recordatorio_1h: Mapped[bool] = mapped_column(Boolean, default=False)
    usuario: Mapped[Usuario] = relationship(back_populates="reservas")
    espacio: Mapped[Espacio] = relationship(back_populates="reservas")
