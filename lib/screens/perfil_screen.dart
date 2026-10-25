import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  Usuario? u;
  String nacimiento = '';
  bool loading = true, saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      u = await Api.miPerfil();
      _nombre.text = u!.nombre;
      _apellido.text = u!.apellido;
      nacimiento = u!.nacimiento;
    } catch (e) {
      error = errorMessage(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _fecha() async {
    final ini = DateTime.tryParse(nacimiento) ?? DateTime(2000);
    final d = await showDatePicker(
        context: context,
        initialDate: ini,
        firstDate: DateTime(1920),
        lastDate: DateTime.now());
    if (d != null) setState(() => nacimiento = isoDate(d));
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty || _apellido.text.trim().isEmpty) {
      showMsg(context, 'Nombre y apellido son obligatorios.', error: true);
      return;
    }
    setState(() => saving = true);
    try {
      await Api.editarPerfil({
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'fecha_nacimiento': nacimiento,
      });
      if (mounted) showMsg(context, 'Perfil actualizado.');
    } catch (e) {
      if (mounted) showMsg(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                    TextButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text('Cerrar sesión')),
                  ]),
                )
              : ListView(padding: const EdgeInsets.all(24), children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '${u!.nombre.isNotEmpty ? u!.nombre[0] : ''}${u!.apellido.isNotEmpty ? u!.apellido[0] : ''}'
                            .toUpperCase(),
                        style: const TextStyle(fontSize: 28, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Modo nocturno'),
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: (v) => ThemeController.instance.setDark(v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _nombre,
                      decoration: const InputDecoration(labelText: 'Nombre')),
                  const SizedBox(height: 14),
                  TextField(
                      controller: _apellido,
                      decoration: const InputDecoration(labelText: 'Apellido')),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _fecha,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento',
                          suffixIcon: Icon(Icons.calendar_today)),
                      child: Text(fmtDate(nacimiento)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(
                        text: u!.email.isNotEmpty
                            ? u!.email
                            : (FirebaseAuth.instance.currentUser?.email ?? '')),
                    decoration: const InputDecoration(labelText: 'Correo (no editable)'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: u!.dni),
                    decoration: const InputDecoration(labelText: 'DNI'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: saving ? null : _guardar,
                    child: saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar cambios'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ]),
    );
  }
}
