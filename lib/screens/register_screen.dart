import 'package:firebase_auth/firebase_auth.dart';

import '../services/notification_service.dart';

import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../models/models.dart';
import '../services/api_service.dart';

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
  final _email = TextEditingController();
  final _pass = TextEditingController();
  DateTime? _nac;
  bool _loading = false;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _nac ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _nac = d);
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    if (_nac == null) {
      showMsg(context, 'Elegí tu fecha de nacimiento.', error: true);
      return;
    }
    setState(() => _loading = true);
    UserCredential? cred;
    try {
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
      await Api.crearPerfil({
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'dni': _dni.text.trim(),
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
      if (mounted) showMsg(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType? type,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
        validator:
            validator ??
            (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            children: [
              _field(_nombre, 'Nombre'),
              _field(_apellido, 'Apellido'),
              _field(
                _dni,
                'DNI',
                type: TextInputType.number,
                validator: (v) {
                  if (v == null || !RegExp(r'^\d{7,8}$').hasMatch(v.trim())) {
                    return 'DNI de 7 u 8 dígitos';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de nacimiento',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _nac == null ? 'Elegir fecha' : fmtDate(isoDate(_nac!)),
                    ),
                  ),
                ),
              ),
              _field(
                _email,
                'Correo electrónico',
                type: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Ingresá un correo válido'
                    : null,
              ),
              _field(
                _pass,
                'Contraseña (mín. 6 caracteres)',
                obscure: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrarme'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
