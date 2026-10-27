import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import 'theme.dart';

TextStyle kickerStyle(Color c) => TextStyle(
    color: c, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 3);

// Letra monoespaciada (para los nombres tecnicos de las canchas).
TextStyle mono(Color color, {double size = 11}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, color: color);

// Colores de respaldo cuando todavia no hay foto del deporte.
List<Color> coloresDeporte(String nombre) {
  final s = norm(nombre);
  if (s.contains('futbol')) return const [Color(0xFF1F6B35), Color(0xFF0B2E17)];
  if (s.contains('tenis')) return const [Color(0xFF1E5F8C), Color(0xFF0A2338)];
  if (s.contains('hockey')) return const [Color(0xFF2D6A4F), Color(0xFF0F2A1E)];
  if (s.contains('voley')) return const [Color(0xFFC8643B), Color(0xFF4A2112)];
  if (s.contains('golf')) return const [Color(0xFF4C9A5B), Color(0xFF1B4332)];
  return const [Color(0xFF2E4B3A), Color(0xFF0F1A14)];
}

const _paletasSede = <List<Color>>[
  [Color(0xFF0E4A6B), Color(0xFF04141F)],
  [Color(0xFF2E6B2E), Color(0xFF0A1F0A)],
  [Color(0xFF2B6CB0), Color(0xFF0B1F36)],
  [Color(0xFF3F7D20), Color(0xFF10260A)],
];
List<Color> coloresSede(int i) => _paletasSede[i % _paletasSede.length];

// Color de la etiqueta de cada deporte (distinto en modo dia y noche).
Color colorDeporte(BuildContext c, String nombre) {
  final s = norm(nombre);
  final n = c.noche;
  if (s.contains('futbol')) return n ? AppColors.verdeNoche : AppColors.verdeDia;
  if (s.contains('tenis')) return n ? AppColors.ambarNoche : AppColors.ambarDia;
  if (s.contains('hockey')) {
    return n ? const Color(0xFFC4A1FF) : const Color(0xFF7A3FD1);
  }
  if (s.contains('voley')) return n ? AppColors.indigoNoche : AppColors.indigoDia;
  if (s.contains('golf')) {
    return n ? const Color(0xFF6FD3E8) : const Color(0xFF0B7A94);
  }
  return c.muted;
}

// Foto desde assets/images/<nombre>.jpg; si no existe, un degrade de color.
class FotoAsset extends StatelessWidget {
  final String nombre;
  final List<Color> colores;
  final String? emoji;
  const FotoAsset(this.nombre, {super.key, required this.colores, this.emoji});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/$nombre.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colores),
        ),
        alignment: Alignment.center,
        child: emoji == null
            ? null
            : Opacity(
                opacity: 0.25,
                child: Text(emoji!, style: const TextStyle(fontSize: 90))),
      ),
    );
  }
}

// Encabezado con foto (o degrade), oscurecido y con degrade hacia el fondo.
class HeroHeader extends StatelessWidget {
  final String foto;
  final List<Color> colores;
  final double altura;
  final Widget child;
  final bool fade;
  final String? emoji;
  const HeroHeader({
    super.key,
    required this.foto,
    required this.colores,
    required this.altura,
    required this.child,
    this.fade = true,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: altura,
      child: Stack(fit: StackFit.expand, children: [
        FotoAsset(foto, colores: colores, emoji: emoji),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withAlpha(110), Colors.black.withAlpha(175)],
            ),
          ),
        ),
        if (fade)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [context.fondo.withAlpha(0), context.fondo],
                ),
              ),
            ),
          ),
        SafeArea(bottom: false, child: child),
      ]),
    );
  }
}

// Caja con borde redondeado (tarjetas).
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.superficie,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.borde),
      ),
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

// Etiqueta chica de color (Outdoor, Iluminada, deporte...).
class Tag extends StatelessWidget {
  final String texto;
  final Color color;
  final String? emoji;
  final IconData? icono;
  const Tag(this.texto, {super.key, required this.color, this.emoji, this.icono});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (emoji != null) ...[
          Text(emoji!, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
        ],
        if (icono != null) ...[
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 5),
        ],
        Text(texto,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }
}

// Boton tipo "pildora" que se marca al elegirlo.
class OpcionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;
  final bool pequeno;
  const OpcionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.pequeno = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.onVerde : context.texto;
    return Material(
      color: selected ? context.verde : context.superficie,
      shape: StadiumBorder(
          side: BorderSide(color: selected ? context.verde : context.borde)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: pequeno ? 14 : 18, vertical: pequeno ? 8 : 11),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (emoji != null) ...[
              Text(emoji!, style: TextStyle(fontSize: pequeno ? 13 : 16)),
              const SizedBox(width: 7),
            ],
            Text(label,
                style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: pequeno ? 13 : 15)),
          ]),
        ),
      ),
    );
  }
}

// "MIS RESERVAS": primera palabra normal, segunda en verde.
class TituloPantalla extends StatelessWidget {
  final String blanco, verde;
  const TituloPantalla(this.blanco, this.verde, {super.key});

  @override
  Widget build(BuildContext context) {
    final base = tituloStyle(context, size: 40);
    return Text.rich(TextSpan(children: [
      TextSpan(text: '${blanco.toUpperCase()} ', style: base),
      TextSpan(text: verde.toUpperCase(), style: base.copyWith(color: context.verde)),
    ]));
  }
}

class EstadoCarga extends StatelessWidget {
  const EstadoCarga({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
}

class EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const EstadoError(this.mensaje, {super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_outlined, size: 52, color: context.muted),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ]),
      ),
    );
  }
}

class EstadoVacio extends StatelessWidget {
  final String mensaje;
  final String emoji;
  const EstadoVacio(this.mensaje, {super.key, this.emoji = '🏟️'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(mensaje,
              textAlign: TextAlign.center, style: TextStyle(color: context.muted)),
        ]),
      ),
    );
  }
}

// dialogo rojo para confirmar cosas que no se pueden deshacer (cancelar reserva, borrar cuenta, eliminar).
// devuelve true si el usuario confirma
Future<bool> confirmarPeligro(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String textoOk,
  String textoCancelar = 'Volver',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: ctx.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.rojo.withAlpha(90)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.rojo, size: 18),
              const SizedBox(width: 8),
              Text(titulo.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.rojo,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      fontSize: 12)),
            ]),
            const SizedBox(height: 14),
            Text(mensaje, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(textoCancelar),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.rojo,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(textoOk),
                ),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
  return r == true;
}
