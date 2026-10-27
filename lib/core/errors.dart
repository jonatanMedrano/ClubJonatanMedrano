import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'theme.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

enum TipoError { conexion, servidor, otro }

// clasifica el error: sin conexion, servidor caido u otro. segun eso se muestra un dialogo o un aviso
TipoError tipoError(Object e) {
  if (e is ApiException) {
    if (e.esConexion) return TipoError.conexion;
    if (e.esServidor) return TipoError.servidor;
  }
  if (e is FirebaseAuthException && e.code == 'network-request-failed') {
    return TipoError.conexion;
  }
  return TipoError.otro;
}

// pasa cualquier excepcion a un mensaje en castellano. los errores de firebase vienen con codigos en ingles y
// aca se traducen
String errorMessage(Object e) {
  if (e is ApiException) return e.message;
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email o contraseña incorrectos.';
      case 'invalid-email':
        return 'El email no es válido.';
      case 'email-already-in-use':
        return 'Ese email ya está registrado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
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

// aviso corto abajo, rojo si es un error
void showMsg(BuildContext c, String m, {bool error = false}) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text(m),
    backgroundColor: error ? Colors.red.shade700 : null,
  ));
}

// Cuadro de dialogo de error (siempre oscuro, como en el diseno).
Future<void> showErrorDialog(BuildContext context, TipoError tipo) {
  final conexion = tipo == TipoError.conexion;
  return showDialog<void>(
    context: context,
    builder: (ctx) => Theme(
      data: buildTheme(Brightness.dark),
      child: Builder(
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0B0B0B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0x66E0645F)),
          ),
          title: Text(
            conexion ? 'ERROR DE CONECTIVIDAD' : 'ERROR DEL SERVIDOR',
            style: const TextStyle(
                color: AppColors.rojo, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w800),
          ),
          content: Text(
            conexion
                ? 'Parece que no estás conectado a ninguna red. Reestablecé tu conexión e intentá otra vez.'
                : 'Parece que hubo un error en el servidor. Por favor, volvé a intentarlo más tarde.',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ACEPTAR'),
            ),
          ],
        ),
      ),
    ),
  );
}

// Muestra el error mas adecuado: dialogo si es de red/servidor, aviso si no.
void mostrarError(BuildContext context, Object e) {
  final t = tipoError(e);
  if (t == TipoError.otro) {
    showMsg(context, errorMessage(e), error: true);
  } else {
    showErrorDialog(context, t);
  }
}
