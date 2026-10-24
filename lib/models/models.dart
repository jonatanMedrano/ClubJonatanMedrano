String two(int n) => n.toString().padLeft(2, '0');
String isoDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
String fmtDate(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
}

String hhmm(String s) => s.length >= 5 ? s.substring(0, 5) : s;
String str(dynamic v) => v == null ? '' : '$v';

class Sede {
  final int id;
  final String nombre, direccion;
  Sede(this.id, this.nombre, this.direccion);
  factory Sede.fromJson(Map<String, dynamic> j) =>
      Sede(j['id'], str(j['nombre']), str(j['direccion']));
}

class Deporte {
  final int id;
  final String nombre;
  Deporte(this.id, this.nombre);
  factory Deporte.fromJson(Map<String, dynamic> j) =>
      Deporte(j['id'], str(j['nombre']));
}

class Espacio {
  final int id;
  final String nombre, sede, deporte, apertura, cierre;
  final double precioHora;
  final bool indoor;
  Espacio(
    this.id,
    this.nombre,
    this.sede,
    this.deporte,
    this.apertura,
    this.cierre,
    this.precioHora,
    this.indoor,
  );

  factory Espacio.fromJson(Map<String, dynamic> j) {
    final s = j['sede'], d = j['deporte'];
    return Espacio(
      j['id'],
      str(j['nombre']),
      str(j['sede_nombre'] ?? (s is Map ? s['nombre'] : s)),
      str(j['deporte_nombre'] ?? (d is Map ? d['nombre'] : d)),
      hhmm(str(j['hora_apertura'])),
      hhmm(str(j['hora_cierre'])),
      double.tryParse(str(j['precio_hora'])) ?? 0,
      j['indoor'] == true,
    );
  }
}

class Reserva {
  final int id;
  final String espacio, sede, fecha, inicio, fin, estado;
  final double total;
  final bool? proximaApi;
  Reserva(
    this.id,
    this.espacio,
    this.sede,
    this.fecha,
    this.inicio,
    this.fin,
    this.estado,
    this.total, {
    this.proximaApi,
  });

  factory Reserva.fromJson(Map<String, dynamic> j) {
    final e = j['espacio'];
    return Reserva(
      j['id'],
      str(j['espacio_nombre'] ?? (e is Map ? e['nombre'] : e)),
      str(j['sede_nombre'] ?? (e is Map ? e['sede'] : '')),
      str(j['fecha']),
      hhmm(str(j['hora_inicio'])),
      hhmm(str(j['hora_fin'])),
      str(j['estado']),
      double.tryParse(str(j['total'])) ?? 0,
      proximaApi: j['proxima'] is bool ? j['proxima'] as bool : null,
    );
  }

  bool get cancelada => estado.toLowerCase().startsWith('cancel');
  DateTime get finDt => DateTime.parse('${fecha}T$fin:00');
  bool get proxima =>
      !cancelada && (proximaApi ?? finDt.isAfter(DateTime.now()));
}

class Usuario {
  final String nombre, apellido, dni, nacimiento, email;
  Usuario(this.nombre, this.apellido, this.dni, this.nacimiento, this.email);
  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
    str(j['nombre']),
    str(j['apellido']),
    str(j['dni']),
    str(j['fecha_nacimiento']),
    str(j['email']),
  );
}
