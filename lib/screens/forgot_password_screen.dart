import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false, _enviado = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.text.trim());
      if (mounted) setState(() => _enviado = true);
    } catch (e) {
      if (!mounted) return;
      if (tipoError(e) == TipoError.otro) {
        setState(() => _error = errorMessage(e));
      } else {
        mostrarError(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Align(alignment: Alignment.centerLeft, child: AuthBack()),
          const SizedBox(height: 8),
          const AuthTitle(
            kicker: 'Recuperación',
            blanco: 'Olvidé mi',
            verde: 'Contraseña',
            subtitulo: 'Ingresá tu email y te enviaremos un enlace.',
          ),
          const SizedBox(height: 28),
          if (_enviado) _Enviado(email: _email.text.trim()) else _formulario(),
        ]),
      ),
    );
  }

  Widget _formulario() {
    return Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AuthField(
          controller: _email,
          hint: 'Tu email registrado',
          type: TextInputType.emailAddress,
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Ingresá tu email';
            if (!t.contains('@') || !t.contains('.')) return 'El email no es válido';
            return null;
          },
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[AuthBanner(_error!), const SizedBox(height: 14)],
        FilledButton(
          onPressed: _loading ? null : _enviar,
          child: _loading
              ? const SizedBox(
                  height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('ENVIAR ENLACE'),
        ),
      ]),
    );
  }
}

class _Enviado extends StatelessWidget {
  final String email;
  const _Enviado({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(children: [
        const Icon(Icons.mark_email_read_outlined, size: 56, color: Colors.white70),
        const SizedBox(height: 16),
        const Text('¡Enlace enviado!',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Revisá tu bandeja en '),
            TextSpan(
                text: email,
                style: const TextStyle(color: AppColors.verdeNoche, fontWeight: FontWeight.w800)),
          ]),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(190, 46)),
          onPressed: () => Navigator.maybePop(context),
          child: const Text('VOLVER AL LOGIN'),
        ),
      ]),
    );
  }
}
