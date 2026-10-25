import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/stores.dart';
import 'admin_widgets.dart';

class AdminCanchasScreen extends StatefulWidget {
  const AdminCanchasScreen({super.key});
  @override
  State<AdminCanchasScreen> createState() => _AdminCanchasScreenState();
}

class _AdminCanchasScreenState extends State<AdminCanchasScreen> {
  List<Espacio> _canchas = [];
  List<Sede> _sedes = [];
  List<Deporte> _deportes = [];
  int? _sedeId; // null = todas
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await Future.wait([Api.espacios(), Api.sedes(), Api.deportes()]);
      if (!mounted) return;
      setState(() {
        _canchas = r[0] as List<Espacio>;
        _sedes = r[1] as List<Sede>;
        _deportes = r[2] as List<Deporte>;
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

  Future<void> _abrir([Espacio? cancha]) async {
    if (_sedes.isEmpty || _deportes.isEmpty) {
      showMsg(context, 'Primero tiene que haber al menos una sede y un deporte.',
          error: true);
      return;
    }
    final ok = await mostrarFormulario(
      context,
      _CanchaForm(cancha: cancha, sedes: _sedes, deportes: _deportes),
    );
    if (ok != true || !mounted) return;
    showMsg(context, cancha == null ? 'Cancha creada.' : 'Cancha actualizada.');
    await _cargar();
    CatalogStore.instance.load();
  }

  Future<void> _eliminar(Espacio e) async {
    final ok = await confirmarPeligro(
      context,
      titulo: 'Eliminar cancha',
      mensaje: '¿Eliminar la cancha ${e.nombre}? Esta acción no se puede deshacer.',
      textoOk: 'Eliminar',
      textoCancelar: 'Cancelar',
    );
    if (!ok || !mounted) return;
    try {
      await Api.adminEliminarEspacio(e.id);
      if (!mounted) return;
      showMsg(context, 'Cancha eliminada.');
      await _cargar();
      CatalogStore.instance.load();
    } catch (err) {
      if (mounted) mostrarError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibles =
        _canchas.where((c) => _sedeId == null || c.sedeId == _sedeId).toList();

    return AdminListaScaffold(
      blanco: 'Gestión',
      verde: 'Canchas',
      textoAgregar: 'Agregar cancha',
      vacio: 'No hay canchas para mostrar.',
      loading: _loading,
      error: _error,
      onRefresh: _cargar,
      onAgregar: () => _abrir(),
      filtros: _sedes.isEmpty
          ? null
          : SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OpcionChip(
                      label: 'Todas',
                      pequeno: true,
                      selected: _sedeId == null,
                      onTap: () => setState(() => _sedeId = null),
                    ),
                  ),
                  for (final s in _sedes)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OpcionChip(
                        label: s.nombre,
                        pequeno: true,
                        selected: _sedeId == s.id,
                        onTap: () => setState(() => _sedeId = s.id),
                      ),
                    ),
                ],
              ),
            ),
      items: [
        for (final c in visibles)
          AdminItem(
            emoji: deporteEmoji(c.deporte),
            titulo: c.nombre,
            subtitulo:
                '${c.sede} · ${c.etiqueta} · ${c.indoor ? 'Indoor' : 'Outdoor'}${c.iluminada ? ' · Iluminada' : ''}',
            detalle: '${fmtPrecio(c.precioHora)}/h · ${c.apertura} – ${c.cierre}',
            onEditar: () => _abrir(c),
            onEliminar: () => _eliminar(c),
          ),
      ],
    );
  }
}

class _CanchaForm extends StatefulWidget {
  final Espacio? cancha;
  final List<Sede> sedes;
  final List<Deporte> deportes;
  const _CanchaForm({this.cancha, required this.sedes, required this.deportes});
  @override
  State<_CanchaForm> createState() => _CanchaFormState();
}

class _CanchaFormState extends State<_CanchaForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _subtipo;
  late final TextEditingController _numero;
  late final TextEditingController _precio;
  int? _sedeId, _deporteId;
  late bool _indoor, _iluminada;
  late int _ap, _ci;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.cancha;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _subtipo = TextEditingController(text: c?.subtipo ?? '');
    _numero = TextEditingController(text: '${c?.numero ?? 1}');
    _precio = TextEditingController(
        text: c == null ? '' : c.precioHora.round().toString());
    _sedeId = widget.sedes.any((s) => s.id == c?.sedeId) ? c?.sedeId : null;
    _deporteId = widget.deportes.any((d) => d.id == c?.deporteId) ? c?.deporteId : null;
    _indoor = c?.indoor ?? false;
    _iluminada = c?.iluminada ?? false;
    _ap = c == null ? 8 : horaDe(c.apertura);
    _ci = c == null ? 23 : horaDe(c.cierre);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _subtipo.dispose();
    _numero.dispose();
    _precio.dispose();
    super.dispose();
  }

  /// Si el nombre queda vacío se arma solo: Moron_Futbol_Futbol5_Cancha_1
  String _nombreAutomatico(int numero) {
    final sede = widget.sedes.firstWhere((s) => s.id == _sedeId);
    final dep = widget.deportes.firstWhere((d) => d.id == _deporteId);
    final sub = _subtipo.text.trim();
    return '${pascal(sede.nombre)}_${pascal(dep.nombre)}'
        '${sub.isEmpty ? '' : '_${pascal(sub)}'}_Cancha_$numero';
  }

  Future<void> _guardar() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (_sedeId == null || _deporteId == null) {
      setState(() => _error = 'Elegí la sede y el deporte.');
      return;
    }
    if (_ap >= _ci) {
      setState(() => _error = 'La apertura debe ser anterior al cierre.');
      return;
    }
    final numero = int.parse(_numero.text.trim());
    final precio = double.parse(_precio.text.trim().replaceAll(',', '.'));
    final nombre =
        _nombre.text.trim().isEmpty ? _nombreAutomatico(numero) : _nombre.text.trim();
    final sub = _subtipo.text.trim();

    setState(() => _guardando = true);
    try {
      await Api.adminGuardarEspacio(widget.cancha?.id, {
        'nombre': nombre,
        'sede_id': _sedeId,
        'deporte_id': _deporteId,
        'subtipo': sub.isEmpty ? null : sub,
        'numero': numero,
        'precio_hora': precio,
        'indoor': _indoor,
        'iluminada': _iluminada,
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

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      formKey: _form,
      titulo: widget.cancha == null ? 'Nueva cancha' : 'Editar cancha',
      guardando: _guardando,
      error: _error,
      onGuardar: _guardar,
      children: [
        CampoSelect<int>(
          label: 'Sede',
          value: _sedeId,
          items: [
            for (final s in widget.sedes)
              DropdownMenuItem(value: s.id, child: Text(s.nombre)),
          ],
          onChanged: (v) => setState(() => _sedeId = v),
        ),
        CampoSelect<int>(
          label: 'Deporte',
          value: _deporteId,
          items: [
            for (final d in widget.deportes)
              DropdownMenuItem(
                  value: d.id, child: Text('${deporteEmoji(d.nombre)}  ${d.nombre}')),
          ],
          onChanged: (v) => setState(() => _deporteId = v),
        ),
        TextFormField(
          controller: _subtipo,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              labelText: 'Tipo (opcional)', hintText: 'Fútbol 5, Cemento, 9 Hoyos...'),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextFormField(
              controller: _numero,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'N° de cancha'),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return (n == null || n < 1) ? 'Mínimo 1' : null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _precio,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Precio por hora', prefixText: '\$ '),
              validator: (v) {
                final p = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                return (p == null || p <= 0) ? 'Ingresá un precio' : null;
              },
            ),
          ),
        ]),
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
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Indoor (techada)'),
          value: _indoor,
          onChanged: (v) => setState(() => _indoor = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Iluminada'),
          value: _iluminada,
          onChanged: (v) => setState(() => _iluminada = v),
        ),
        TextFormField(
          controller: _nombre,
          decoration: const InputDecoration(
            labelText: 'Nombre técnico (opcional)',
            helperText: 'Si lo dejás vacío se genera solo.',
          ),
        ),
      ],
    );
  }
}
