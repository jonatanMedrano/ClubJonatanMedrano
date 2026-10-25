import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _dni = TextEditingController();
  final _fecha = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  DateTime? _nac;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _dni, _fecha, _email, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _nac ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: buildTheme(Brightness.dark), child: child!),
    );
    if (d != null) {
      _nac = d;
      _fecha.text = fmtDate(isoDate(d));
    }
  }

  String? _obligatorio(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  Future<void> _register() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    UserCredential? cred;
    try {
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text);
      await Api.crearPerfil({
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'dni': _dni.text.replaceAll('.', '').trim(),
        'fecha_nacimiento': isoDate(_nac!),
        'email': _email.text.trim(),
      });
      NotificationService.init();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      // Si falló el perfil (ej. DNI repetido) no dejamos el usuario a medias.
      try {
        await cred?.user?.delete();
      } catch (_) {}
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
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Align(alignment: Alignment.centerLeft, child: AuthBack()),
            const SizedBox(height: 8),
            const AuthTitle(kicker: 'Nueva cuenta', blanco: 'Crear', verde: 'Cuenta'),
            const SizedBox(height: 24),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: AuthField(
                  label: 'Nombre',
                  hint: 'Juan',
                  controller: _nombre,
                  validator: (v) => _obligatorio(v, 'Obligatorio'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthField(
                  label: 'Apellido',
                  hint: 'Pérez',
                  controller: _apellido,
                  validator: (v) => _obligatorio(v, 'Obligatorio'),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            AuthField(
              label: 'DNI',
              hint: '31234567',
              controller: _dni,
              type: TextInputType.number,
              validator: (v) {
                final t = (v ?? '').replaceAll('.', '').trim();
                if (t.isEmpty) return 'Ingresá tu DNI';
                if (!RegExp(r'^\d{7,8}$').hasMatch(t)) return 'El DNI debe tener 7 u 8 dígitos';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthField(
              label: 'Fecha de nacimiento',
              hint: 'Elegir fecha',
              controller: _fecha,
              readOnly: true,
              onTap: _elegirFecha,
              suffixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 20),
              validator: (v) => _obligatorio(v, 'Elegí tu fecha de nacimiento'),
            ),
            const SizedBox(height: 14),
            AuthField(
              label: 'Email',
              hint: 'juan@email.com',
              controller: _email,
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
              label: 'Contraseña',
              hint: 'Mínimo 8 caracteres',
              controller: _pass,
              password: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresá una contraseña';
                if (v.length < 8) return 'Mínimo 8 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[AuthBanner(_error!), const SizedBox(height: 14)],
            FilledButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(
                      height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('CREAR CUENTA'),
            ),
          ]),
        ),
      ),
    );
  }
}
