from datetime import date, datetime, time
from decimal import Decimal
from typing import Optional

from sqlalchemy import (Boolean, Date, DateTime, ForeignKey, Index, Numeric,
                        String, Time, func)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


class Sede(Base):
    __tablename__ = "sedes"
    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(80), unique=True)
    direccion: Mapped[str] = mapped_column(String(120))
    hora_apertura: Mapped[time] = mapped_column(Time, default=time(8, 0))
    hora_cierre: Mapped[time] = mapped_column(Time, default=time(23, 0))
    espacios: Mapped[list["Espacio"]] = relationship(back_populates="sede")


class Deporte(Base):
    __tablename__ = "deportes"
    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(40), unique=True)
    espacios: Mapped[list["Espacio"]] = relationship(back_populates="deporte")


class Espacio(Base):
    __tablename__ = "espacios"
    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(120), unique=True)
    numero: Mapped[int]
    precio_hora: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    indoor: Mapped[bool] = mapped_column(Boolean, default=False)
    hora_apertura: Mapped[time] = mapped_column(Time)
    hora_cierre: Mapped[time] = mapped_column(Time)
    sede_id: Mapped[int] = mapped_column(ForeignKey("sedes.id"))
    deporte_id: Mapped[int] = mapped_column(ForeignKey("deportes.id"))
    sede: Mapped[Sede] = relationship(back_populates="espacios")
    deporte: Mapped[Deporte] = relationship(back_populates="espacios")
    reservas: Mapped[list["Reserva"]] = relationship(back_populates="espacio")


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
    reservas: Mapped[list["Reserva"]] = relationship(
        back_populates="usuario", cascade="all, delete-orphan"
    )


class Reserva(Base):
    __tablename__ = "reservas"
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
    recordatorio_24h: Mapped[bool] = mapped_column(Boolean, default=False)
    recordatorio_1h: Mapped[bool] = mapped_column(Boolean, default=False)
    usuario: Mapped[Usuario] = relationship(back_populates="reservas")
    espacio: Mapped[Espacio] = relationship(back_populates="reservas")
