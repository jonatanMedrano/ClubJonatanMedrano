import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/stores.dart';
import 'admin_widgets.dart';

class AdminSedesScreen extends StatefulWidget {
  const AdminSedesScreen({super.key});
  @override
  State<AdminSedesScreen> createState() => _AdminSedesScreenState();
}

class _AdminSedesScreenState extends State<AdminSedesScreen> {
  List<Sede> _sedes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await Api.sedes();
      if (!mounted) return;
      setState(() {
        _sedes = r;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _abrir([Sede? sede]) async {
    final ok = await mostrarFormulario(context, _SedeForm(sede: sede));
    if (ok != true || !mounted) return;
    showMsg(context, sede == null ? 'Sede creada.' : 'Sede actualizada.');
    await _cargar();
    CatalogStore.instance.load();
  }

  Future<void> _eliminar(Sede s) async {
    final ok = await confirmarPeligro(
      context,
      titulo: 'Eliminar sede',
      mensaje: '¿Eliminar la sede ${s.nombre}? Esta acción no se puede deshacer.',
      textoOk: 'Eliminar',
      textoCancelar: 'Cancelar',
    );
    if (!ok || !mounted) return;
    try {
      await Api.adminEliminarSede(s.id);
      if (!mounted) return;
      showMsg(context, 'Sede eliminada.');
      await _cargar();
      CatalogStore.instance.load();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminListaScaffold(
      blanco: 'Gestión',
      verde: 'Sedes',
      textoAgregar: 'Agregar sede',
      vacio: 'Todavía no hay sedes.',
      loading: _loading,
      error: _error,
      onRefresh: _cargar,
      onAgregar: () => _abrir(),
      items: [
        for (final s in _sedes)
          AdminItem(
            emoji: '🏢',
            titulo: 'Sede ${s.nombre}',
            subtitulo: s.direccion,
            detalle:
                '${s.apertura} – ${s.cierre} · ${s.cantidadCanchas} ${s.cantidadCanchas == 1 ? 'cancha' : 'canchas'}',
            onEditar: () => _abrir(s),
            onEliminar: () => _eliminar(s),
          ),
      ],
    );
  }
}

class _SedeForm extends StatefulWidget {
  final Sede? sede;
  const _SedeForm({this.sede});
  @override
  State<_SedeForm> createState() => _SedeFormState();
}

class _SedeFormState extends State<_SedeForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _direccion;
  late int _ap, _ci;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.sede;
    _nombre = TextEditingController(text: s?.nombre ?? '');
    _direccion = TextEditingController(text: s?.direccion ?? '');
    _ap = s == null ? 8 : horaDe(s.apertura);
    _ci = s == null ? 23 : horaDe(s.cierre);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (_ap >= _ci) {
      setState(() => _error = 'La apertura debe ser anterior al cierre.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await Api.adminGuardarSede(widget.sede?.id, {
        'nombre': _nombre.text.trim(),
        'direccion': _direccion.text.trim(),
        'hora_apertura': '${two(_ap)}:00',
        'hora_cierre': '${two(_ci)}:00',
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String? _obligatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      formKey: _form,
      titulo: widget.sede == null ? 'Nueva sede' : 'Editar sede',
      guardando: _guardando,
      error: _error,
      onGuardar: _guardar,
      children: [
        TextFormField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre (ej: Morón)'),
          validator: _obligatorio,
        ),
        TextFormField(
          controller: _direccion,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Dirección'),
          validator: _obligatorio,
        ),
        Row(children: [
          Expanded(
            child: CampoHora(
                label: 'Apertura', value: _ap, onChanged: (v) => setState(() => _ap = v)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CampoHora(
                label: 'Cierre', value: _ci, onChanged: (v) => setState(() => _ci = v)),
          ),
        ]),
      ],
    );
  }
}
