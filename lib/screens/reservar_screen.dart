import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/stores.dart';
import 'reserva_confirmada_screen.dart';

class _Slot {
  final int hora;
  final bool libre;
  const _Slot(this.hora, this.libre);
}

class ReservarScreen extends StatefulWidget {
  final Espacio espacio;
  final List<Espacio> hermanas; // canchas del mismo deporte y subtipo
  const ReservarScreen({super.key, required this.espacio, required this.hermanas});
  @override
  State<ReservarScreen> createState() => _ReservarScreenState();
}

class _ReservarScreenState extends State<ReservarScreen> {
  late Espacio _sel;
  late final List<DateTime> _dias;
  late DateTime _fecha;
  int _duracion = 1;
  int? _inicio;
  List<Franja> _franjas = [];
  bool _loading = true, _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sel = widget.espacio;
    final h = DateTime.now();
    final hoy = DateTime(h.year, h.month, h.day);
    _dias = List.generate(14, (i) => hoy.add(Duration(days: i)));
    _fecha = hoy;
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
      _inicio = null;
    });
    try {
      _franjas = await Api.disponibilidad(_sel.id, isoDate(_fecha));
    } catch (e) {
      _error = errorMessage(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Horarios posibles según la duración elegida.
  List<_Slot> get _slots {
    if (_franjas.isEmpty) return [];
    final libre = {for (final f in _franjas) f.hora: f.disponible};
    final cierre = _franjas.last.hora + 1;
    final out = <_Slot>[];
    for (final f in _franjas) {
      if (f.hora + _duracion > cierre) continue;
      var ok = true;
      for (var k = 0; k < _duracion; k++) {
        if (libre[f.hora + k] != true) ok = false;
      }
      out.add(_Slot(f.hora, ok));
    }
    return out;
  }

  Future<void> _confirmar() async {
    final inicio = _inicio;
    if (inicio == null) return;
    setState(() => _saving = true);
    try {
      await Api.crearReserva(_sel.id, isoDate(_fecha), '${two(inicio)}:00',
          '${two(inicio + _duracion)}:00');
      NotificationStore.instance.add('Reserva confirmada',
          '${_sel.deporte} ${two(inicio)}:00 · ${fmtCorto(_fecha)}');
      ReservasStore.instance.load(silent: true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ReservaConfirmadaScreen()));
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e);
      _cargar(); // por si alguien ocupó el horario mientras tanto
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _encabezado(Espacio e) {
    final sub = e.subtipo;
    if (sub == null) return e.deporte.toUpperCase();
    return '${e.deporte.toUpperCase()} · ${sub.toUpperCase()}';
  }

  Widget _etiqueta(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(t,
            style: TextStyle(
                color: context.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5)),
      );

  @override
  Widget build(BuildContext context) {
    final e = _sel;
    return Scaffold(
      body: Stack(children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 250,
          child: HeroHeader(
            foto: 'sede_${slug(e.sede)}',
            colores: coloresDeporte(e.deporte),
            altura: 250,
            fade: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Volver'),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_encabezado(e), style: kickerStyle(Colors.white70)),
                    const SizedBox(height: 4),
                    Text('SEDE ${e.sede.toUpperCase()}',
                        style: tituloStyle(context, size: 36, color: Colors.white)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        Positioned.fill(
          top: 190,
          child: Container(
            decoration: BoxDecoration(
              color: context.fondo,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: _hoja(context),
            ),
          ),
        ),
      ]),
    );
  }

  List<Widget> _hoja(BuildContext context) {
    final e = _sel;
    final slots = _slots;
    final ocupados = slots.where((s) => !s.libre).length;
    final ancho = (MediaQuery.of(context).size.width - 40 - 10) / 2;
    final total = e.precioHora * _duracion;

    return [
      // ---- Cancha ----
      _etiqueta('SELECCIONÁ CANCHA'),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final c in widget.hermanas)
          _CanchaOpcion(
            titulo: 'Cancha ${c.numero}',
            subtitulo: c.indoor ? 'Indoor' : 'Outdoor',
            selected: c.id == e.id,
            onTap: () {
              if (c.id == e.id) return;
              setState(() => _sel = c);
              _cargar();
            },
          ),
      ]),

      // ---- Fecha ----
      _etiqueta('FECHA'),
      SizedBox(
        height: 78,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _dias.length,
          itemBuilder: (_, i) {
            final d = _dias[i];
            final sel = d == _fecha;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _DiaOpcion(
                dia: diaSem(d).toUpperCase(),
                numero: '${d.day}',
                selected: sel,
                onTap: () {
                  if (sel) return;
                  setState(() => _fecha = d);
                  _cargar();
                },
              ),
            );
          },
        ),
      ),

      // ---- Duración ----
      _etiqueta('DURACIÓN'),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.chipBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borde),
        ),
        child: Row(children: [
          for (final h in const [1, 2])
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _duracion = h;
                  _inicio = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _duracion == h ? context.verde : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(h == 1 ? '1 hora' : '2 horas',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _duracion == h ? context.onVerde : context.muted)),
                ),
              ),
            ),
        ]),
      ),

      // ---- Horarios ----
      _etiqueta('HORARIO DISPONIBLE'),
      if (_loading)
        const EstadoCarga()
      else if (_error != null)
        EstadoError(_error!, onRetry: _cargar)
      else if (slots.isEmpty)
        const EstadoVacio('No hay horarios para ese día.')
      else ...[
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final s in slots)
            _HorarioOpcion(
              ancho: ancho,
              texto: '${two(s.hora)}:00 - ${two(s.hora + _duracion)}:00',
              libre: s.libre,
              selected: _inicio == s.hora,
              onTap: () => setState(() => _inicio = s.hora),
            ),
        ]),
        if (ocupados > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(children: [
              Icon(Icons.info_outline, size: 15, color: context.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Algunos horarios están ocupados · $ocupados no disponibles',
                    style: TextStyle(color: context.muted, fontSize: 12)),
              ),
            ]),
          ),
      ],

      // ---- Resumen ----
      const SizedBox(height: 22),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(e.etiqueta,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            Text('${fmtPrecio(e.precioHora)} × $_duracion',
                style: mono(context.muted, size: 12)),
          ]),
          const SizedBox(height: 2),
          Text('${e.deporte} · ${_duracion}h',
              style: TextStyle(color: context.muted, fontSize: 13)),
          Divider(height: 24, color: context.borde),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total', style: TextStyle(color: context.muted, fontSize: 13)),
                Text(fmtPrecio(total), style: tituloStyle(context, size: 36)),
              ]),
            ),
            if (_inicio != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${two(_inicio!)}:00 - ${two(_inicio! + _duracion)}:00',
                    style: tituloStyle(context, size: 22, color: context.verde)),
                Text(fmtCorto(_fecha),
                    style: TextStyle(color: context.muted, fontSize: 12)),
              ]),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: (_inicio == null || _saving) ? null : _confirmar,
        child: _saving
            ? const SizedBox(
                height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(_inicio == null ? 'SELECCIONÁ UN HORARIO' : 'CONFIRMAR RESERVA'),
      ),
    ];
  }
}

class _CanchaOpcion extends StatelessWidget {
  final String titulo, subtitulo;
  final bool selected;
  final VoidCallback onTap;
  const _CanchaOpcion({
    required this.titulo,
    required this.subtitulo,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.onVerde : context.texto;
    return Material(
      color: selected ? context.verde : context.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? context.verde : context.borde),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(titulo, style: tituloStyle(context, size: 20, color: fg)),
            const SizedBox(height: 2),
            Text(subtitulo,
                style: TextStyle(color: fg.withAlpha(170), fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

class _DiaOpcion extends StatelessWidget {
  final String dia, numero;
  final bool selected;
  final VoidCallback onTap;
  const _DiaOpcion({
    required this.dia,
    required this.numero,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.onVerde : context.texto;
    return Material(
      color: selected ? context.verde : context.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? context.verde : context.borde),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(dia,
                style: TextStyle(
                    color: fg.withAlpha(170), fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(numero, style: tituloStyle(context, size: 28, color: fg)),
          ]),
        ),
      ),
    );
  }
}

class _HorarioOpcion extends StatelessWidget {
  final double ancho;
  final String texto;
  final bool libre, selected;
  final VoidCallback onTap;
  const _HorarioOpcion({
    required this.ancho,
    required this.texto,
    required this.libre,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? context.onVerde
        : (libre ? context.texto : context.muted.withAlpha(90));
    return SizedBox(
      width: ancho,
      child: Material(
        color: selected
            ? context.verde
            : (libre ? context.superficie : context.chipBg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? context.verde : context.borde),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: libre ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: Text(
                texto,
                style: tituloStyle(context, size: 18, color: fg).copyWith(
                  decoration: libre ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
