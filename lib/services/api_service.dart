import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// Todas las llamadas al backend FastAPI. Si una ruta de tu API se llama
/// distinto, se cambia SOLO acá.
class Api {
  static Future<dynamic> _send(String method, String path,
      {Map<String, String>? query, Object? body, bool auth = true}) async {
    var uri = Uri.parse('${Config.baseUrl}$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    try {
      final req = http.Request(method, uri)
        ..headers['Content-Type'] = 'application/json';
      if (auth) {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token != null) req.headers['Authorization'] = 'Bearer $token';
      }
      if (body != null) req.body = jsonEncode(body);
      final res = await http.Response.fromStream(
          await req.send().timeout(const Duration(seconds: 60)));
      final text = utf8.decode(res.bodyBytes);
      dynamic data;
      if (text.isNotEmpty) {
        try {
          data = jsonDecode(text);
        } catch (_) {}
      }
      if (res.statusCode >= 200 && res.statusCode < 300) return data;
      throw ApiException(_mensaje(res.statusCode, data), res.statusCode);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Sin conexión a internet.');
    } on TimeoutException {
      throw ApiException(
          'El servidor tardó demasiado en responder. Intentá de nuevo.');
    } on http.ClientException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('refused')) {
        throw ApiException('El servidor no está disponible.');
      }
      if (m.contains('lookup') ||
          m.contains('unreachable') ||
          m.contains('network')) {
        throw ApiException('Sin conexión a internet.');
      }
      throw ApiException('No se pudo conectar con el servidor.');
    }
  }

  static String _mensaje(int code, dynamic data) {
    if (code == 401) return 'Tu sesión expiró. Volvé a iniciar sesión.';
    if (code >= 500) return 'El servidor no está disponible. Intentá más tarde.';
    if (data is Map && data['detail'] != null) {
      final d = data['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty && d.first is Map) {
        return '${d.first['msg'] ?? 'Datos inválidos'}';
      }
    }
    return 'No se pudo completar la operación ($code).';
  }

  static List<Map<String, dynamic>> _list(dynamic d) =>
      (d as List).cast<Map<String, dynamic>>();

  // ---------- Públicos ----------
  static Future<List<Sede>> sedes() async =>
      _list(await _send('GET', '/sedes', auth: false))
          .map(Sede.fromJson)
          .toList();

  static Future<List<Deporte>> deportes() async =>
      _list(await _send('GET', '/deportes', auth: false))
          .map(Deporte.fromJson)
          .toList();

  static Future<List<Espacio>> espacios({int? sedeId, int? deporteId}) async {
    final q = <String, String>{};
    if (sedeId != null) q['sede_id'] = '$sedeId';
    if (deporteId != null) q['deporte_id'] = '$deporteId';
    return _list(await _send('GET', '/espacios', query: q, auth: false))
        .map(Espacio.fromJson)
        .toList();
  }

  /// Devuelve las horas de INICIO libres (ej: [18, 19, 20]).
  static Future<List<int>> horasLibres(int espacioId, String fecha) async {
    final d = await _send('GET', '/espacios/$espacioId/disponibilidad',
        query: {'fecha': fecha}, auth: false);
    final list = d is Map ? (d['horarios'] ?? d['disponibles'] ?? []) : d;
    final out = <int>[];
    for (final it in list as List) {
      if (it is Map) {
        if (it['disponible'] == false) continue;
        out.add(int.parse(str(it['hora_inicio'] ?? it['hora']).substring(0, 2)));
      } else {
        out.add(int.parse('$it'.substring(0, 2)));
      }
    }
    out.sort();
    return out;
  }

  // ---------- Con login ----------
  static Future<void> crearPerfil(Map<String, dynamic> body) =>
      _send('POST', '/usuarios', body: body);

  static Future<Usuario> miPerfil() async =>
      Usuario.fromJson(await _send('GET', '/usuarios/me'));

  static Future<void> editarPerfil(Map<String, dynamic> body) =>
      _send('PUT', '/usuarios/me', body: body);

  static Future<void> crearReserva(
          int espacioId, String fecha, String inicio, String fin) =>
      _send('POST', '/reservas', body: {
        'espacio_id': espacioId,
        'fecha': fecha,
        'hora_inicio': inicio,
        'hora_fin': fin,
      });

  static Future<List<Reserva>> misReservas() async =>
      _list(await _send('GET', '/reservas/mias')).map(Reserva.fromJson).toList();

  static Future<void> cancelarReserva(int id) =>
      _send('PATCH', '/reservas/$id/cancelar');

  static Future<void> guardarFcmToken(String token) =>
      _send('PUT', '/usuarios/me/fcm-token', body: {'token': token});
}
