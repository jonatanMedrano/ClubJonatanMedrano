import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors.dart';
import '../models/models.dart';
import 'api_service.dart';

// pestana activa del menu de abajo: 0 inicio, 1 sedes, 2 reservas, 3 perfil. esta aca para poder cambiarla
// desde cualquier pantalla
class NavController {
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);
}

// perfil del usuario logueado. las pantallas escuchan este objeto y se redibujan cuando cambia
// (notifyListeners)
class UserStore extends ChangeNotifier {
  UserStore._();
  static final UserStore instance = UserStore._();

  Usuario? usuario;
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      usuario = await Api.miPerfil();
    } catch (e) {
      error = errorMessage(e);
    }
    loading = false;
    notifyListeners();
  }

  void clear() {
    usuario = null;
    error = null;
    loading = false;
    notifyListeners();
  }
}

// sedes y deportes, datos publicos que se cargan una vez al abrir el home
class CatalogStore extends ChangeNotifier {
  CatalogStore._();
  static final CatalogStore instance = CatalogStore._();

  List<Sede> sedes = [];
  List<Deporte> deportes = [];
  bool loading = false;
  bool loaded = false;
  String? error;

  int get totalCanchas => sedes.fold(0, (a, s) => a + s.cantidadCanchas);

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final r = await Future.wait([Api.sedes(), Api.deportes()]);
      sedes = r[0] as List<Sede>;
      deportes = r[1] as List<Deporte>;
      loaded = true;
    } catch (e) {
      error = errorMessage(e);
    }
    loading = false;
    notifyListeners();
  }
}

// reservas del usuario. proximas e historial salen del campo proxima que calcula la api
class ReservasStore extends ChangeNotifier {
  ReservasStore._();
  static final ReservasStore instance = ReservasStore._();

  List<Reserva> items = [];
  bool loading = false;
  bool loaded = false;
  String? error;

  int _cmp(Reserva a, Reserva b) =>
      '${a.fecha}${a.inicio}'.compareTo('${b.fecha}${b.inicio}');

  List<Reserva> get proximas => items.where((r) => r.proxima).toList()..sort(_cmp);
  List<Reserva> get historial =>
      items.where((r) => !r.proxima).toList()..sort((a, b) => _cmp(b, a));
  Reserva? get siguiente => proximas.isEmpty ? null : proximas.first;

  // con silent en true recarga sin mostrar el cartel de carga, se usa despues de reservar o cancelar
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      items = await Api.misReservas();
      error = null;
      loaded = true;
    } catch (e) {
      if (!silent) error = errorMessage(e);
    }
    loading = false;
    notifyListeners();
  }

  void clear() {
    items = [];
    loaded = false;
    loading = false;
    error = null;
    notifyListeners();
  }
}

// un aviso del historial
class AppNotif {
  final String titulo, cuerpo;
  final int ts;
  final bool leida;
  const AppNotif(this.titulo, this.cuerpo, this.ts, this.leida);

  Map<String, dynamic> toJson() =>
      {'t': titulo, 'b': cuerpo, 'ts': ts, 'r': leida};

  factory AppNotif.fromJson(Map<String, dynamic> j) =>
      AppNotif('${j['t']}', '${j['b']}', (j['ts'] as num).toInt(), j['r'] == true);

  AppNotif comoLeida() => AppNotif(titulo, cuerpo, ts, true);
  DateTime get fecha => DateTime.fromMillisecondsSinceEpoch(ts);
}

// historial de avisos de la campana. se guarda en el celular con shared_preferences, uno por usuario porque la
// clave incluye el uid, y maximo 30
class NotificationStore extends ChangeNotifier {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  List<AppNotif> items = [];
  Future<void>? _carga;

  bool get hayNoLeidas => items.any((n) => !n.leida);

  String get _clave =>
      'notifs_${FirebaseAuth.instance.currentUser?.uid ?? 'anon'}';

  Future<void> load() => _carga ??= _cargar();

  Future<void> _cargar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_clave);
      if (raw != null) {
        items = (jsonDecode(raw) as List)
            .map((e) => AppNotif.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _guardar() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_clave, jsonEncode(items.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  // agrega al principio y deja como maximo 30 avisos
  Future<void> add(String titulo, String cuerpo) async {
    await load();
    items.insert(
        0, AppNotif(titulo, cuerpo, DateTime.now().millisecondsSinceEpoch, false));
    if (items.length > 30) items = items.sublist(0, 30);
    notifyListeners();
    await _guardar();
  }

  Future<void> marcarLeidas() async {
    if (!hayNoLeidas) return;
    items = items.map((n) => n.comoLeida()).toList();
    notifyListeners();
    await _guardar();
  }

  // al cerrar sesion se vacia la memoria, lo que esta guardado en el celular queda
  void clear() {
    items = [];
    _carga = null;
    notifyListeners();
  }
}
