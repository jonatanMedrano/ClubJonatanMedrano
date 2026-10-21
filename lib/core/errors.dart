import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

String errorMessage(Object e) {
  if (e is ApiException) return e.message;
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'email-already-in-use':
        return 'Ese correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      case 'too-many-requests':
        return 'Demasiados intentos. Probá más tarde.';
      default:
        return 'Error de autenticación (${e.code}).';
    }
  }
  return 'Ocurrió un error inesperado. Intentá de nuevo.';
}

void showMsg(BuildContext c, String m, {bool error = false}) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text(m),
    backgroundColor: error ? Colors.red.shade700 : null,
  ));
}
