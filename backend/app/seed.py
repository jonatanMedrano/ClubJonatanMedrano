# carga las 4 sedes, los 5 deportes y las 22 canchas
# python -m app.seed           solo si la base esta vacia
# python -m app.seed --reset   reemplaza sedes, canchas y reservas, los usuarios se quedan
import sys
from datetime import time
from decimal import Decimal

from sqlalchemy import delete, select

from .database import Base, SessionLocal, engine, migrar_columnas
from .models import Deporte, Espacio, Reserva, Sede

DEPORTES = ["Fútbol", "Tenis", "Hockey", "Vóley", "Golf"]
SLUG = {"Fútbol": "Futbol", "Tenis": "Tenis", "Hockey": "Hockey", "Vóley": "Voley", "Golf": "Golf"}

# cada cancha: (deporte, subtipo, slug, numero, indoor, iluminada, precio por hora, apertura, cierre)
SEDES = [
    ("Morón", "Moron_Rivadavia", "Av. Rivadavia 17500", [
        ("Fútbol", "Fútbol 5", "F5", 1, False, True, 3800, 8, 23),
        ("Fútbol", "Fútbol 5", "F5", 2, True, False, 4200, 8, 23),
        ("Fútbol", "Fútbol 7", "F7", 1, False, True, 5500, 8, 22),
        ("Fútbol", "Fútbol 11", "F11", 1, False, True, 9000, 9, 21),
        ("Tenis", "Polvo de Ladrillo", "Polvo", 1, False, True, 2500, 8, 23),
        ("Tenis", "Polvo de Ladrillo", "Polvo", 2, False, False, 2500, 8, 22),
        ("Tenis", "Cemento", "Cemento", 1, True, True, 3000, 8, 23),
    ]),
    ("Ramos Mejía", "RamosMejia_Belgrano", "Calle Belgrano 1240", [
        ("Fútbol", "Fútbol 11", "F11", 1, False, True, 8000, 9, 22),
        ("Fútbol", "Fútbol 5", "F5", 1, True, False, 4000, 9, 22),
        ("Hockey", "Hockey 7", "H7", 1, False, True, 3500, 8, 22),
        ("Vóley", "Indoor Parquet", "Indoor", 1, True, True, 2800, 8, 23),
    ]),
    ("San Justo", "SanJusto_Casanova", "Av. Casanova 320", [
        ("Fútbol", "Fútbol 5", "F5", 1, True, False, 4200, 8, 23),
        ("Fútbol", "Fútbol 5", "F5", 2, False, True, 3600, 8, 22),
        ("Fútbol", "Fútbol 8", "F8", 1, False, True, 6500, 9, 21),
        ("Tenis", "Sintético", "Sint", 1, True, True, 3200, 8, 23),
        ("Golf", "Driving Range", "DrivingRange", 1, False, True, 1500, 8, 20),
        ("Golf", "9 Hoyos", "9Hoyos", 1, False, False, 4500, 8, 18),
    ]),
    ("Castelar", "Castelar_Rivadavia", "Av. Rivadavia 22500", [
        ("Hockey", "Hockey 11", "H11", 1, False, True, 5000, 8, 22),
        ("Tenis", "Cemento", "Cemento", 1, True, False, 3100, 8, 23),
        ("Tenis", "Polvo de Ladrillo", "Polvo", 1, False, True, 2700, 8, 23),
        ("Vóley", "Vóley Playa", "Playa", 1, False, True, 2200, 9, 21),
        ("Vóley", "Indoor Parquet", "Indoor", 1, True, True, 2600, 9, 22),
    ]),
]


# el horario de cada sede es el mas amplio de sus canchas (apertura minima y cierre maximo), asi las canchas
# siempre entran en el horario de la sede
def main(reset: bool = False) -> None:
    Base.metadata.create_all(bind=engine)
    migrar_columnas()
    with SessionLocal() as db:
        if db.scalar(select(Sede.id).limit(1)):
            if not reset:
                print("La base ya tiene datos. Usá --reset para reemplazarlos "
                      "(borra reservas, canchas, sedes y deportes; conserva usuarios).")
                return
            for modelo in (Reserva, Espacio, Sede, Deporte):
                db.execute(delete(modelo))
            db.commit()

        deportes = {n: Deporte(nombre=n) for n in DEPORTES}
        db.add_all(deportes.values())
        total = 0
        for nombre, prefijo, direccion, canchas in SEDES:
            sede = Sede(
                nombre=nombre, direccion=direccion,
                hora_apertura=time(min(c[7] for c in canchas)),
                hora_cierre=time(max(c[8] for c in canchas)),
            )
            db.add(sede)
            for dep, sub, slug, n, indoor, ilum, precio, ap, ci in canchas:
                db.add(Espacio(
                    nombre=f"{prefijo}_{SLUG[dep]}_{slug}_Cancha_{n}", numero=n,
                    subtipo=sub, precio_hora=Decimal(precio), indoor=indoor,
                    iluminada=ilum, hora_apertura=time(ap), hora_cierre=time(ci),
                    sede=sede, deporte=deportes[dep]))
                total += 1
        db.commit()
        print(f"Listo: {len(SEDES)} sedes, {len(DEPORTES)} deportes y {total} canchas.")


if __name__ == "__main__":
    main(reset="--reset" in sys.argv)
