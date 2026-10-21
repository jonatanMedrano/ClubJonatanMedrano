import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/errors.dart';
import 'api_service.dart';

class NotificationService {
  static bool _listening = false;

  static Future<void> init() async {
    try {
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission(); // Android 13+
      final token = await fm.getToken();
      if (token != null) await Api.guardarFcmToken(token);
      if (_listening) return;
      _listening = true;
      fm.onTokenRefresh.listen((t) => Api.guardarFcmToken(t).catchError((_) {}));
      // Con la app abierta FCM no muestra nada solo: mostramos un aviso.
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n == null) return;
        messengerKey.currentState?.showSnackBar(SnackBar(
          content: Text('${n.title ?? ''}\n${n.body ?? ''}'.trim()),
          duration: const Duration(seconds: 6),
        ));
      });
    } catch (_) {
      // Las notificaciones nunca deben romper la app.
    }
  }
}
