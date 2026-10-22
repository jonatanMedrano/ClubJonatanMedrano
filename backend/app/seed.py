"""Carga sedes, deportes y las 22 canchas.  Uso:  python -m app.seed"""
from datetime import time
from decimal import Decimal

from sqlalchemy import select

from .database import Base, SessionLocal, engine
from .models import Deporte, Espacio, Sede

DEPORTES = ["Fútbol", "Tenis", "Hockey", "Vóley", "Golf"]
PRECIO = {"Fútbol": 40000, "Tenis": 15000, "Hockey": 35000, "Vóley": 20000, "Golf": 30000}
SLUG = {"Fútbol": "Futbol", "Tenis": "Tenis", "Hockey": "Hockey", "Vóley": "Voley", "Golf": "Golf"}

# nombre, prefijo del nombre de cancha, dirección, apertura, cierre, {deporte: cantidad}
# Cambiá las calles/horarios por los reales de tu TP.
SEDES = [
    ("Morón", "Moron_Rivadavia_19850", "Rivadavia 19850, Morón", 8, 23,
     {"Fútbol": 2, "Tenis": 2, "Hockey": 1, "Vóley": 1}),
    ("Ramos Mejía", "RamosMejia_DeMayo_250", "Av. de Mayo 250, Ramos Mejía", 8, 23,
     {"Fútbol": 2, "Tenis": 1, "Vóley": 1, "Golf": 1, "Hockey": 1}),
    ("San Justo", "SanJusto_Arieta_3200", "Arieta 3200, San Justo", 9, 23,
     {"Fútbol": 2, "Tenis": 1, "Hockey": 1, "Vóley": 1}),
    ("Castelar", "Castelar_SantaRosa_1500", "Santa Rosa 1500, Castelar", 9, 22,
     {"Fútbol": 2, "Tenis": 1, "Golf": 1, "Vóley": 1}),
]


def main() -> None:
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        if db.scalar(select(Sede.id).limit(1)):
            print("La base ya tiene datos. No se carga nada.")
            return
        deportes = {n: Deporte(nombre=n) for n in DEPORTES}
        db.add_all(deportes.values())
        total = 0
        for nombre, prefijo, direccion, ap, ci, canchas in SEDES:
            sede = Sede(nombre=nombre, direccion=direccion,
                        hora_apertura=time(ap), hora_cierre=time(ci))
            db.add(sede)
            for dep, cant in canchas.items():
                for n in range(1, cant + 1):
                    db.add(Espacio(
                        nombre=f"{prefijo}_{SLUG[dep]}_{n}", numero=n,
                        precio_hora=Decimal(PRECIO[dep]), indoor=(n % 2 == 0),
                        hora_apertura=time(ap), hora_cierre=time(ci),
                        sede=sede, deporte=deportes[dep]))
                    total += 1
        db.commit()
        print(f"Listo: {len(SEDES)} sedes, {len(DEPORTES)} deportes y {total} canchas.")


if __name__ == "__main__":
    main()
