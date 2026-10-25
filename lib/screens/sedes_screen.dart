import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../services/stores.dart';
import 'sede_detalle_screen.dart';

class SedesScreen extends StatelessWidget {
  const SedesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CatalogStore.instance,
      builder: (context, _) {
        final cat = CatalogStore.instance;
        Widget cuerpo;
        if (cat.loading && !cat.loaded) {
          cuerpo = const EstadoCarga();
        } else if (cat.error != null && !cat.loaded) {
          cuerpo = EstadoError(cat.error!, onRetry: cat.load);
        } else if (cat.sedes.isEmpty) {
          cuerpo = const EstadoVacio('Todavía no hay sedes cargadas.');
        } else {
          cuerpo = Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(children: [
              for (var i = 0; i < cat.sedes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _SedeCard(
                    sede: cat.sedes[i],
                    indice: i,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              SedeDetalleScreen(sede: cat.sedes[i], indice: i)),
                    ),
                  ),
                ),
            ]),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: cat.load,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                HeroHeader(
                  foto: 'home_hero',
                  colores: const [Color(0xFF1B5E20), Color(0xFF03140A)],
                  emoji: '🏟️',
                  altura: 190,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CLUB JONATAN MEDRANO',
                            style: kickerStyle(AppColors.verdeNoche)),
                        const SizedBox(height: 6),
                        Text.rich(TextSpan(children: [
                          TextSpan(
                              text: 'TODAS LAS ',
                              style: tituloStyle(context, size: 38, color: Colors.white)),
                          TextSpan(
                              text: 'SEDES',
                              style: tituloStyle(context,
                                  size: 38, color: AppColors.verdeNoche)),
                        ])),
                        if (cat.loaded) ...[
                          const SizedBox(height: 4),
                          Text(
                              '${cat.sedes.length} sedes · ${cat.totalCanchas} canchas disponibles',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),
                cuerpo,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SedeCard extends StatelessWidget {
  final Sede sede;
  final int indice;
  final VoidCallback onTap;
  const _SedeCard({required this.sede, required this.indice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.superficie,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.borde),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(children: [
          SizedBox(
            height: 160,
            child: Stack(fit: StackFit.expand, children: [
              FotoAsset('sede_${slug(sede.nombre)}', colores: coloresSede(indice)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(200)],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 14,
                right: 90,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SEDE ${sede.nombre.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tituloStyle(context, size: 28, color: Colors.white)),
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
                  ],
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${sede.cantidadCanchas}',
                        style: tituloStyle(context,
                            size: 24, color: AppColors.verdeNoche)),
                    const Text('canchas',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ]),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final d in sede.deportes)
                    Tag(d, emoji: deporteEmoji(d), color: colorDeporte(context, d)),
                ]),
              ),
              const SizedBox(width: 8),
              Text('Ver canchas →',
                  style: TextStyle(color: context.verde, fontWeight: FontWeight.w800)),
            ]),
          ),
        ]),
      ),
    );
  }
}
