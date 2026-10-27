import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/stores.dart';
import 'admin_widgets.dart';

class AdminDeportesScreen extends StatefulWidget {
  const AdminDeportesScreen({super.key});
  @override
  State<AdminDeportesScreen> createState() => _AdminDeportesScreenState();
}

class _AdminDeportesScreenState extends State<AdminDeportesScreen> {
  List<Deporte> _deportes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await Api.deportes();
      if (!mounted) return;
      setState(() {
        _deportes = r;
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

  // abre el formulario, sin deporte es alta y con deporte es edicion
  Future<void> _abrir([Deporte? deporte]) async {
    final ok = await mostrarFormulario(context, _DeporteForm(deporte: deporte));
    if (ok != true || !mounted) return;
    showMsg(context, deporte == null ? 'Deporte creado.' : 'Deporte actualizado.');
    await _cargar();
    CatalogStore.instance.load();
  }

  // si el deporte tiene canchas la api responde 409 y se muestra el motivo
  Future<void> _eliminar(Deporte d) async {
    final ok = await confirmarPeligro(
      context,
      titulo: 'Eliminar deporte',
      mensaje: '¿Eliminar el deporte ${d.nombre}? Esta acción no se puede deshacer.',
      textoOk: 'Eliminar',
      textoCancelar: 'Cancelar',
    );
    if (!ok || !mounted) return;
    try {
      await Api.adminEliminarDeporte(d.id);
      if (!mounted) return;
      showMsg(context, 'Deporte eliminado.');
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
      verde: 'Deportes',
      textoAgregar: 'Agregar deporte',
      vacio: 'Todavía no hay deportes.',
      loading: _loading,
      error: _error,
      onRefresh: _cargar,
      onAgregar: () => _abrir(),
      items: [
        for (final d in _deportes)
          AdminItem(
            emoji: deporteEmoji(d.nombre),
            titulo: d.nombre,
            onEditar: () => _abrir(d),
            onEliminar: () => _eliminar(d),
          ),
      ],
    );
  }
}

class _DeporteForm extends StatefulWidget {
  final Deporte? deporte;
  const _DeporteForm({this.deporte});
  @override
  State<_DeporteForm> createState() => _DeporteFormState();
}

class _DeporteFormState extends State<_DeporteForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.deporte?.nombre ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await Api.adminGuardarDeporte(
          widget.deporte?.id, {'nombre': _nombre.text.trim()});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      formKey: _form,
      titulo: widget.deporte == null ? 'Nuevo deporte' : 'Editar deporte',
      guardando: _guardando,
      error: _error,
      onGuardar: _guardar,
      children: [
        TextFormField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre (ej: Pádel)'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
        ),
      ],
    );
  }
}
