import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/stores.dart';
import 'admin_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  String _nacimiento = '';
  bool _editando = false, _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    super.dispose();
  }

  void _editar(Usuario u) {
    _nombre.text = u.nombre;
    _apellido.text = u.apellido;
    _nacimiento = u.nacimiento;
    setState(() => _editando = true);
  }

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_nacimiento) ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _nacimiento = isoDate(d));
  }

  // edita nombre, apellido y fecha de nacimiento en la api (el dni y el mail no se pueden cambiar)
  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty || _apellido.text.trim().isEmpty) {
      showMsg(context, 'Nombre y apellido son obligatorios.', error: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      await Api.editarPerfil({
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'fecha_nacimiento': _nacimiento,
      });
      await UserStore.instance.load();
      if (mounted) {
        setState(() => _editando = false);
        showMsg(context, 'Perfil actualizado.');
      }
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // vacia los stores para que al entrar otro usuario no vea datos del anterior
  void _limpiarSesion() {
    UserStore.instance.clear();
    ReservasStore.instance.clear();
    NotificationStore.instance.clear();
    NavController.tab.value = 0;
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    _limpiarSesion();
  }

  // borra la cuenta: la api elimina el perfil con sus reservas y la cuenta de firebase, despues se cierra la
  // sesion
  Future<void> _eliminarCuenta() async {
    final ok = await confirmarPeligro(
      context,
      titulo: 'Zona de peligro',
      mensaje: '¿Estás seguro? Esta acción elimina todos tus datos permanentemente.',
      textoOk: 'Eliminar',
      textoCancelar: 'Cancelar',
    );
    if (!ok || !mounted) return;
    try {
      await Api.eliminarCuenta();
      await FirebaseAuth.instance.signOut();
      _limpiarSesion();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserStore.instance,
      builder: (context, _) {
        final store = UserStore.instance;
        final u = store.usuario;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                const TituloPantalla('Mi', 'Perfil'),
                const SizedBox(height: 18),
                if (u == null && store.loading)
                  const EstadoCarga()
                else if (u == null)
                  Column(children: [
                    EstadoError(store.error ?? 'No pudimos cargar tu perfil.',
                        onRetry: store.load),
                    OutlinedButton.icon(
                      onPressed: _cerrarSesion,
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ])
                else
                  ..._contenido(context, u),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _contenido(BuildContext context, Usuario u) {
    final noche = context.noche;
    return [
      // ---- Cabecera ----
      Row(children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: context.verde, borderRadius: BorderRadius.circular(22)),
          child: Text(u.iniciales,
              style: tituloStyle(context, size: 30, color: context.onVerde)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.nombreCompleto, style: tituloStyle(context, size: 26)),
            const SizedBox(height: 4),
            Text(u.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.muted, fontSize: 13)),
            const SizedBox(height: 4),
            Text(u.esAdmin ? 'ADMINISTRADOR' : 'MIEMBRO ACTIVO',
                style: kickerStyle(context.verde).copyWith(fontSize: 10, letterSpacing: 2.5)),
          ]),
        ),
      ]),
      const SizedBox(height: 18),

      // ---- Modo nocturno ----
      Panel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: [
          Icon(noche ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: context.muted),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Modo nocturno', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Switch(
            value: noche,
            onChanged: (v) => ThemeController.instance.setDark(v),
          ),
        ]),
      ),
      const SizedBox(height: 14),

      // ---- Datos personales ----
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('DATOS PERSONALES',
                  style: TextStyle(
                      color: context.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5)),
            ),
            if (_editando) ...[
              TextButton(
                onPressed: _guardando ? null : () => setState(() => _editando = false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14)),
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check, size: 18),
                label: const Text('GUARDAR'),
              ),
            ] else
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                onPressed: () => _editar(u),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
              ),
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _campo('NOMBRE', u.nombre, controller: _nombre)),
            const SizedBox(width: 12),
            Expanded(child: _campo('APELLIDO', u.apellido, controller: _apellido)),
          ]),
          const SizedBox(height: 14),
          _campo('DNI', fmtDni(u.dni), bloqueado: true),
          const SizedBox(height: 14),
          _campoFecha(u),
          const SizedBox(height: 14),
          _campo('EMAIL (SOLO LECTURA)', u.email, bloqueado: true, candado: true),
        ]),
      ),
      const SizedBox(height: 14),

      if (u.esAdmin) ...[
        FilledButton.icon(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AdminScreen())),
          icon: const Icon(Icons.admin_panel_settings_outlined),
          label: const Text('GESTIÓN ADMIN'),
        ),
        const SizedBox(height: 14),
      ],

      // ---- Cerrar sesion ----
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: context.verde,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _cerrarSesion,
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      const SizedBox(height: 14),

      // ---- Zona de peligro ----
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.rojo.withAlpha(noche ? 25 : 30),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.rojo.withAlpha(90)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.rojo, size: 18),
            const SizedBox(width: 8),
            Text('ZONA DE PELIGRO',
                style: kickerStyle(AppColors.rojo).copyWith(letterSpacing: 2.5)),
          ]),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.rojo,
              foregroundColor: Colors.white,
            ),
            onPressed: _eliminarCuenta,
            icon: const Icon(Icons.delete_outline),
            label: const Text('ELIMINAR CUENTA'),
          ),
        ]),
      ),
    ];
  }

  Widget _etiqueta(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: TextStyle(
                color: context.muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
      );

  // Campo de solo lectura (con el mismo aspecto que un campo de texto).
  Widget _valor(String texto, {bool apagado = false, Widget? sufijo}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: context.chipBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borde),
      ),
      child: Row(children: [
        Expanded(
          child: Text(texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: apagado ? context.muted : context.texto)),
        ),
        if (sufijo != null) sufijo,
      ]),
    );
  }

  Widget _campo(String label, String valor,
      {TextEditingController? controller, bool bloqueado = false, bool candado = false}) {
    final editable = _editando && controller != null && !bloqueado;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _etiqueta(label),
      if (editable)
        TextField(controller: controller, textCapitalization: TextCapitalization.words)
      else
        _valor(valor,
            apagado: bloqueado,
            sufijo: candado ? Icon(Icons.lock_outline, size: 16, color: context.muted) : null),
    ]);
  }

  Widget _campoFecha(Usuario u) {
    final texto = fmtDate(_editando ? _nacimiento : u.nacimiento);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _etiqueta('FECHA DE NACIMIENTO'),
      GestureDetector(
        onTap: _editando ? _elegirFecha : null,
        child: _valor(texto,
            sufijo: _editando
                ? Icon(Icons.calendar_today_outlined, size: 18, color: context.muted)
                : null),
      ),
    ]);
  }
}
