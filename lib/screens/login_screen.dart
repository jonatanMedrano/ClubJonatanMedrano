import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      const credenciales = ['invalid-credential', 'wrong-password', 'user-not-found', 'invalid-email'];
      if (credenciales.contains(e.code)) {
        setState(() => _error = errorMessage(e));
      } else {
        mostrarError(context, e);
      }
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const AuthTitle(
                kicker: 'Bienvenido a',
                blanco: 'Club',
                verde: 'Jonatan Medrano',
                subtitulo: 'Gestión de espacios deportivos',
              ),
              const SizedBox(height: 32),
              AuthField(
                controller: _email,
                hint: 'Email',
                type: TextInputType.emailAddress,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Ingresá tu email';
                  if (!t.contains('@') || !t.contains('.')) return 'El email no es válido';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthField(
                controller: _pass,
                hint: 'Contraseña',
                password: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Ingresá tu contraseña' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: const Text('¿Olvidaste tu contraseña?',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              if (_error != null) ...[AuthBanner(_error!), const SizedBox(height: 14)],
              FilledButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('INICIAR SESIÓN'),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('¿No tenés cuenta? ', style: TextStyle(color: Colors.white54)),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: Text('COMENZAR →',
                      style: TextStyle(
                          color: AppColors.verdeNoche,
                          fontWeight: FontWeight.w800)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
