import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Pestaña activa del menú inferior (0 Inicio, 1 Sedes, 2 Reservas, 3 Perfil).
class NavController {
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);
}

/// Datos del usuario que inició sesión.
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

/// Sedes y deportes (datos públicos).
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

/// Reservas del usuario (próximas e historial).
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

/// Historial de avisos de la app, guardado en el celular (uno por usuario).
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

  /// Al cerrar sesión: vacía la memoria (los datos del usuario quedan guardados).
  void clear() {
    items = [];
    _carga = null;
    notifyListeners();
  }
}
