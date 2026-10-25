String two(int n) => n.toString().padLeft(2, '0');
String isoDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
String fmtDate(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
}

String hhmm(String s) => s.length >= 5 ? s.substring(0, 5) : s;
String str(dynamic v) => v == null ? '' : '$v';

const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];
String diaSem(DateTime d) => _dias[d.weekday - 1];
String mesAbr(DateTime d) => _meses[d.month - 1];

/// "sáb, 15 ago"
String fmtCorto(DateTime d) => '${diaSem(d)}, ${d.day} ${mesAbr(d)}';
String fmtCortoIso(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : fmtCorto(d);
}

/// 3800 -> "$ 3.800"
String fmtPrecio(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '\$ $b';
}

/// 31234567 -> "31.234.567"
String fmtDni(String d) {
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) b.write('.');
    b.write(d[i]);
  }
  return b.toString();
}

/// Minúsculas y sin tildes, para comparar nombres.
String norm(String s) => s
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ü', 'u')
    .replaceAll('ñ', 'n');

/// "Ramos Mejía" -> "ramos_mejia"
String slug(String s) => norm(s)
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

String deporteEmoji(String nombre) {
  final s = norm(nombre);
  if (s.contains('futbol')) return '⚽';
  if (s.contains('tenis')) return '🎾';
  if (s.contains('hockey')) return '🏑';
  if (s.contains('voley')) return '🏐';
  if (s.contains('golf')) return '⛳';
  return '🏟️';
}

class Sede {
  final int id;
  final String nombre, direccion, apertura, cierre;
  final int cantidadCanchas;
  final List<String> deportes;
  const Sede({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.apertura,
    required this.cierre,
    required this.cantidadCanchas,
    required this.deportes,
  });

  factory Sede.fromJson(Map<String, dynamic> j) => Sede(
        id: j['id'] as int,
        nombre: str(j['nombre']),
        direccion: str(j['direccion']),
        apertura: hhmm(str(j['hora_apertura'])),
        cierre: hhmm(str(j['hora_cierre'])),
        cantidadCanchas: (j['cantidad_canchas'] as num?)?.toInt() ?? 0,
        deportes: ((j['deportes'] as List?) ?? const []).map((e) => '$e').toList(),
      );
}

class Deporte {
  final int id;
  final String nombre;
  const Deporte(this.id, this.nombre);
  factory Deporte.fromJson(Map<String, dynamic> j) =>
      Deporte(j['id'] as int, str(j['nombre']));
}

class Espacio {
  final int id, numero, sedeId, deporteId;
  final String nombre, sede, deporte, apertura, cierre;
  final String? subtipo;
  final double precioHora;
  final bool indoor, iluminada;
  const Espacio({
    required this.id,
    required this.numero,
    required this.nombre,
    required this.subtipo,
    required this.sedeId,
    required this.sede,
    required this.deporteId,
    required this.deporte,
    required this.apertura,
    required this.cierre,
    required this.precioHora,
    required this.indoor,
    required this.iluminada,
  });

  factory Espacio.fromJson(Map<String, dynamic> j) => Espacio(
        id: j['id'] as int,
        numero: (j['numero'] as num?)?.toInt() ?? 1,
        nombre: str(j['nombre']),
        subtipo: j['subtipo'] == null ? null : str(j['subtipo']),
        sedeId: (j['sede_id'] as num?)?.toInt() ?? 0,
        sede: str(j['sede_nombre']),
        deporteId: (j['deporte_id'] as num?)?.toInt() ?? 0,
        deporte: str(j['deporte_nombre']),
        apertura: hhmm(str(j['hora_apertura'])),
        cierre: hhmm(str(j['hora_cierre'])),
        precioHora: double.tryParse(str(j['precio_hora'])) ?? 0,
        indoor: j['indoor'] == true,
        iluminada: j['iluminada'] == true,
      );

  /// "Fútbol 5", "Cemento", etc. Si no tiene subtipo, el nombre del deporte.
  String get etiqueta => subtipo ?? deporte;
}

/// Una hora de una cancha para una fecha, y si se puede reservar.
class Franja {
  final int hora;
  final bool disponible;
  const Franja(this.hora, this.disponible);
}

class Reserva {
  final int id;
  final String espacio, sede, fecha, inicio, fin, estado;
  final double total;
  final bool? proximaApi;
  const Reserva(this.id, this.espacio, this.sede, this.fecha, this.inicio,
      this.fin, this.estado, this.total,
      {this.proximaApi});

  factory Reserva.fromJson(Map<String, dynamic> j) => Reserva(
        j['id'] as int,
        str(j['espacio_nombre']),
        str(j['sede_nombre']),
        str(j['fecha']),
        hhmm(str(j['hora_inicio'])),
        hhmm(str(j['hora_fin'])),
        str(j['estado']),
        double.tryParse(str(j['total'])) ?? 0,
        proximaApi: j['proxima'] is bool ? j['proxima'] as bool : null,
      );

  bool get cancelada => estado.toLowerCase().startsWith('cancel');
  DateTime get inicioDt => DateTime.parse('${fecha}T$inicio:00');
  DateTime get finDt => DateTime.parse('${fecha}T$fin:00');
  bool get proxima =>
      !cancelada && (proximaApi ?? finDt.isAfter(DateTime.now()));
  String get estadoLabel =>
      cancelada ? 'Cancelada' : (proxima ? 'Activa' : 'Completada');

  /// "hoy", "mañana", "en 3 días"
  String get enDias {
    final h = DateTime.now();
    final a = DateTime(h.year, h.month, h.day);
    final d = inicioDt;
    final n = DateTime(d.year, d.month, d.day).difference(a).inDays;
    if (n <= 0) return 'hoy';
    if (n == 1) return 'mañana';
    return 'en $n días';
  }
}

class Usuario {
  final String nombre, apellido, dni, nacimiento, email;
  final bool esAdmin;
  const Usuario(this.nombre, this.apellido, this.dni, this.nacimiento,
      this.email, this.esAdmin);

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        str(j['nombre']),
        str(j['apellido']),
        str(j['dni']),
        str(j['fecha_nacimiento']),
        str(j['email']),
        j['es_admin'] == true,
      );

  String get nombreCompleto => '$nombre $apellido'.trim();
  String get iniciales =>
      '${nombre.isNotEmpty ? nombre[0] : ''}${apellido.isNotEmpty ? apellido[0] : ''}'
          .toUpperCase();
}
