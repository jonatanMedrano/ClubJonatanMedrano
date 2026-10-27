import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../services/stores.dart';
import 'notificaciones.dart';
import 'sede_detalle_screen.dart';

// pestana de inicio: saludo, proxima reserva, filtro por deporte y listado de sedes. escucha a los cuatro
// stores a la vez y se redibuja cuando cambia alguno
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});
  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  String? _deporte; // null = todos

  // al tirar hacia abajo se recargan todos los datos en paralelo
  Future<void> _refrescar() => Future.wait([
        CatalogStore.instance.load(),
        ReservasStore.instance.load(),
        UserStore.instance.load(),
      ]);

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return 'BUENOS DÍAS,';
    if (h < 20) return 'BUENAS TARDES,';
    return 'BUENAS NOCHES,';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        UserStore.instance,
        CatalogStore.instance,
        ReservasStore.instance,
        NotificationStore.instance,
      ]),
      builder: (context, _) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _header(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: _proxima(context),
                ),
                _filtros(context),
                _sedes(context),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Encabezado ----------
  Widget _header(BuildContext context) {
    final u = UserStore.instance.usuario;
    return HeroHeader(
      foto: 'home_hero',
      colores: const [Color(0xFF1B5E20), Color(0xFF03140A)],
      emoji: '⚽',
      altura: 270,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_saludo(),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12, letterSpacing: 2)),
                const SizedBox(height: 2),
                Text(u?.nombreCompleto ?? 'Bienvenido',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tituloStyle(context, size: 26, color: Colors.white)),
              ]),
            ),
            _Campana(
              hayNuevas: NotificationStore.instance.hayNoLeidas,
              onTap: () => mostrarNotificaciones(context),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => NavController.tab.value = 3,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.verdeNoche, shape: BoxShape.circle),
                child: Text(u?.iniciales ?? '·',
                    style: tituloStyle(context, size: 18, color: Colors.black)),
              ),
            ),
          ]),
          const Spacer(),
          Text('CLUB JONATAN MEDRANO',
              style: kickerStyle(AppColors.verdeNoche)),
          const SizedBox(height: 6),
          Text('ZONA DEPORTIVA',
              style: tituloStyle(context, size: 42, color: Colors.white)),
        ]),
      ),
    );
  }

  // ---------- Proxima reserva ----------
  Widget _proxima(BuildContext context) {
    final rs = ReservasStore.instance;
    if (rs.loading && !rs.loaded) {
      return const Panel(child: SizedBox(height: 70, child: EstadoCarga()));
    }
    final r = rs.siguiente;
    if (r == null) {
      return Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PRÓXIMA RESERVA', style: kickerStyle(context.verde)),
          const SizedBox(height: 10),
          Text(
            rs.error != null
                ? 'No pudimos cargar tus reservas.'
                : 'Todavía no tenés reservas próximas.',
            style: TextStyle(color: context.muted),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            onPressed: () {
              if (rs.error != null) {
                rs.load();
              } else {
                NavController.tab.value = 1;
              }
            },
            child: Text(rs.error != null ? 'REINTENTAR' : 'RESERVAR AHORA'),
          ),
        ]),
      );
    }
    return Panel(
      onTap: () => NavController.tab.value = 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('PRÓXIMA RESERVA', style: kickerStyle(context.verde))),
          Text('${r.enDias} →', style: TextStyle(color: context.muted, fontSize: 13)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: context.chipBg, borderRadius: BorderRadius.circular(14)),
            child: Text(deporteEmoji(r.espacio), style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sede ${r.sede}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 3),
              Text(r.espacio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mono(context.muted, size: 10)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(r.inicio, style: tituloStyle(context, size: 26, color: context.verde)),
            Text(r.fin, style: TextStyle(color: context.muted, fontSize: 12)),
          ]),
        ]),
        Divider(height: 26, color: context.borde),
        Row(children: [
          Expanded(
              child: Text(fmtCortoIso(r.fecha), style: TextStyle(color: context.muted))),
          Text(fmtPrecio(r.total), style: tituloStyle(context, size: 24)),
        ]),
      ]),
    );
  }

  // ---------- Filtros por deporte ----------
  Widget _filtros(BuildContext context) {
    final deportes = CatalogStore.instance.deportes;
    if (deportes.isEmpty) return const SizedBox(height: 8);
    return SizedBox(
      height: 62,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OpcionChip(
              label: 'Todos',
              selected: _deporte == null,
              onTap: () => setState(() => _deporte = null),
            ),
          ),
          for (final d in deportes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OpcionChip(
                label: d.nombre,
                emoji: deporteEmoji(d.nombre),
                selected: _deporte == d.nombre,
                onTap: () => setState(() => _deporte = d.nombre),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- Sedes ----------
  Widget _sedes(BuildContext context) {
    final cat = CatalogStore.instance;
    final lista = cat.sedes
        .where((s) => _deporte == null || s.deportes.contains(_deporte))
        .toList();

    Widget cuerpo;
    if (cat.loading && !cat.loaded) {
      cuerpo = const EstadoCarga();
    } else if (cat.error != null && !cat.loaded) {
      cuerpo = EstadoError(cat.error!, onRetry: cat.load);
    } else if (lista.isEmpty) {
      cuerpo = const EstadoVacio('No hay sedes con ese deporte.');
    } else {
      cuerpo = SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: lista.length,
          itemBuilder: (_, i) {
            final s = lista[i];
            final indice = cat.sedes.indexOf(s);
            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _SedeMini(
                sede: s,
                indice: indice,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          SedeDetalleScreen(sede: s, indice: indice, deporteInicial: _deporte)),
                ),
              ),
            );
          },
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(children: [
          Expanded(child: Text('SEDES DISPONIBLES', style: tituloStyle(context, size: 24))),
          GestureDetector(
            onTap: () => NavController.tab.value = 1,
            child: Text('Ver todas →',
                style: TextStyle(color: context.verde, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
      cuerpo,
    ]);
  }
}

class _Campana extends StatelessWidget {
  final bool hayNuevas;
  final VoidCallback onTap;
  const _Campana({required this.hayNuevas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withAlpha(60),
            border: Border.all(color: Colors.white30),
          ),
          child: const Icon(Icons.notifications_none, color: Colors.white),
        ),
        if (hayNuevas)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                  color: AppColors.verdeNoche, shape: BoxShape.circle),
            ),
          ),
      ]),
    );
  }
}

class _SedeMini extends StatelessWidget {
  final Sede sede;
  final int indice;
  final VoidCallback onTap;
  const _SedeMini({required this.sede, required this.indice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Material(
        color: context.superficie,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.borde),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 124,
              child: Stack(fit: StackFit.expand, children: [
                FotoAsset('sede_${slug(sede.nombre)}', colores: coloresSede(indice)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(190)],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 10,
                  child: Text(sede.nombre.toUpperCase(),
                      style: tituloStyle(context, size: 24, color: Colors.white)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 15, color: context.muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(sede.direccion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.muted, fontSize: 13)),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.schedule, size: 15, color: context.muted),
                  const SizedBox(width: 4),
                  Text('${sede.apertura} a ${sede.cierre} hs',
                      style: TextStyle(color: context.muted, fontSize: 13)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final d in sede.deportes)
                    Tag(d, emoji: deporteEmoji(d), color: colorDeporte(context, d)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
