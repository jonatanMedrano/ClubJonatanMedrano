import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'reservar_screen.dart';

class SedeDetalleScreen extends StatefulWidget {
  final Sede sede;
  final int indice;
  final String? deporteInicial;
  const SedeDetalleScreen({
    super.key,
    required this.sede,
    required this.indice,
    this.deporteInicial,
  });
  @override
  State<SedeDetalleScreen> createState() => _SedeDetalleScreenState();
}

class _SedeDetalleScreenState extends State<SedeDetalleScreen> {
  List<Espacio> _espacios = [];
  bool _loading = true;
  String? _error;
  String? _deporte;
  String? _subtipo; // null = Todos

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // trae las canchas de esta sede y deja elegido el primer deporte, o el que vino desde el inicio
  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _espacios = await Api.espacios(sedeId: widget.sede.id);
      final deps = _deportes;
      if (_deporte == null || !deps.contains(_deporte)) {
        _deporte = deps.contains(widget.deporteInicial)
            ? widget.deporteInicial
            : (deps.isEmpty ? null : deps.first);
      }
    } catch (e) {
      _error = errorMessage(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  // Deportes de la sede, en el orden en que vienen del servidor.
  List<String> get _deportes {
    final out = <String>[];
    for (final e in _espacios) {
      if (!out.contains(e.deporte)) out.add(e.deporte);
    }
    return out;
  }

  List<Espacio> get _delDeporte =>
      _espacios.where((e) => e.deporte == _deporte).toList();

  // el subtipo es la variante dentro de un deporte, por ejemplo futbol 5 o futbol 7
  List<String> get _subtipos {
    final out = <String>[];
    for (final e in _delDeporte) {
      final s = e.subtipo;
      if (s != null && !out.contains(s)) out.add(s);
    }
    return out;
  }

  List<Espacio> get _visibles =>
      _delDeporte.where((e) => _subtipo == null || e.subtipo == _subtipo).toList();

  // abre la reserva pasando las canchas hermanas (mismo deporte y subtipo) para poder cambiar de cancha sin
  // volver atras
  void _reservar(Espacio e) {
    final hermanas = _espacios
        .where((x) => x.deporteId == e.deporteId && x.subtipo == e.subtipo)
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ReservarScreen(espacio: e, hermanas: hermanas)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sede = widget.sede;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            HeroHeader(
              foto: 'sede_${slug(sede.nombre)}',
              colores: coloresSede(widget.indice),
              altura: 240,
              fade: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Todas las sedes'),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('SEDE', style: kickerStyle(AppColors.verdeNoche)),
                      const SizedBox(height: 4),
                      Text('SEDE ${sede.nombre.toUpperCase()}',
                          style: tituloStyle(context, size: 38, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(sede.direccion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.schedule, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('Abierto de ${sede.apertura} a ${sede.cierre} hs',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
            if (_loading)
              const EstadoCarga()
            else if (_error != null)
              EstadoError(_error!, onRetry: _cargar)
            else if (_espacios.isEmpty)
              const EstadoVacio('Esta sede todavía no tiene canchas.')
            else
              ..._contenido(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _contenido(BuildContext context) {
    final visibles = _visibles;
    return [
      // Deportes
      SizedBox(
        height: 66,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          children: [
            for (final d in _deportes)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OpcionChip(
                  label: d,
                  emoji: deporteEmoji(d),
                  selected: _deporte == d,
                  onTap: () => setState(() {
                    _deporte = d;
                    _subtipo = null;
                  }),
                ),
              ),
          ],
        ),
      ),
      // Subtipos
      if (_subtipos.length > 1)
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OpcionChip(
                  label: 'Todos',
                  pequeno: true,
                  selected: _subtipo == null,
                  onTap: () => setState(() => _subtipo = null),
                ),
              ),
              for (final s in _subtipos)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OpcionChip(
                    label: s,
                    pequeno: true,
                    selected: _subtipo == s,
                    onTap: () => setState(() => _subtipo = s),
                  ),
                ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Text(
          '${visibles.length} ${visibles.length == 1 ? 'cancha' : 'canchas'} · ${_deporte ?? ''}',
          style: TextStyle(color: context.muted),
        ),
      ),
      for (final e in visibles)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _CanchaCard(espacio: e, onReservar: () => _reservar(e)),
        ),
      const SizedBox(height: 8),
    ];
  }
}

// tarjeta de una cancha con precio, horario, indoor u outdoor e iluminacion
class _CanchaCard extends StatelessWidget {
  final Espacio espacio;
  final VoidCallback onReservar;
  const _CanchaCard({required this.espacio, required this.onReservar});

  @override
  Widget build(BuildContext context) {
    final e = espacio;
    final ambar = context.noche ? AppColors.ambarNoche : AppColors.ambarDia;
    final indigo = context.noche ? AppColors.indigoNoche : AppColors.indigoDia;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borde),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 150,
          child: Stack(fit: StackFit.expand, children: [
            FotoAsset(slug(e.deporte),
                colores: coloresDeporte(e.deporte), emoji: deporteEmoji(e.deporte)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(30), Colors.black.withAlpha(190)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(e.etiqueta,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150), shape: BoxShape.circle),
                child: Text(deporteEmoji(e.deporte), style: const TextStyle(fontSize: 16)),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Text(e.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mono(AppColors.verdeNoche, size: 10.5)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Wrap(spacing: 8, runSpacing: 6, children: [
                  e.indoor
                      ? Tag('Indoor', color: indigo, icono: Icons.roofing)
                      : Tag('Outdoor', color: ambar, icono: Icons.wb_sunny_outlined),
                  if (e.iluminada)
                    Tag('Iluminada', color: context.verde, icono: Icons.lightbulb_outline),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmtPrecio(e.precioHora), style: tituloStyle(context, size: 26)),
                Text('/ hora', style: TextStyle(color: context.muted, fontSize: 11)),
              ]),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.schedule, size: 15, color: context.muted),
              const SizedBox(width: 6),
              Text('${e.apertura} – ${e.cierre}',
                  style: TextStyle(color: context.muted, fontSize: 13)),
            ]),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onReservar,
              icon: const Icon(Icons.bolt, size: 20),
              label: const Text('VER HORARIOS / RESERVAR'),
            ),
          ]),
        ),
      ]),
    );
  }
}
