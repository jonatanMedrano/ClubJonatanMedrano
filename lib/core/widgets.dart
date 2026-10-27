import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

// Fondo de las pantallas de acceso (siempre oscuro, como en el diseno).
// Si existe assets/images/login_bg.jpg se usa como foto de fondo.
class AuthScaffold extends StatelessWidget {
  final Widget child;
  const AuthScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(Brightness.dark),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [
          Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _FondoDefault(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withAlpha(140), Colors.black.withAlpha(215), Colors.black],
              ),
            ),
          ),
          SafeArea(child: child),
        ]),
      ),
    );
  }
}

class _FondoDefault extends StatelessWidget {
  const _FondoDefault();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.8, -0.6),
          radius: 1.2,
          colors: [Color(0xFF14532D), Colors.black],
        ),
      ),
      child: const Align(
        alignment: Alignment(0.9, -0.3),
        child: Icon(Icons.sports_soccer, size: 220, color: Color(0x22FFFFFF)),
      ),
    );
  }
}

// "BIENVENIDO A / CLUB JONATAN MEDRANO"
class AuthTitle extends StatelessWidget {
  final String kicker, blanco, verde;
  final String? subtitulo;
  const AuthTitle({
    super.key,
    required this.kicker,
    required this.blanco,
    required this.verde,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final g = Theme.of(context).colorScheme.primary;
    final estilo = GoogleFonts.barlowCondensed(
        fontSize: 42, fontWeight: FontWeight.w800, height: 1.0, letterSpacing: 0.5);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(kicker.toUpperCase(),
          style: TextStyle(color: g, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 4)),
      const SizedBox(height: 10),
      Text.rich(TextSpan(children: [
        TextSpan(text: '${blanco.toUpperCase()} ', style: estilo.copyWith(color: Colors.white)),
        TextSpan(text: verde.toUpperCase(), style: estilo.copyWith(color: g)),
      ])),
      if (subtitulo != null) ...[
        const SizedBox(height: 10),
        Text(subtitulo!, style: const TextStyle(color: Colors.white60, fontSize: 14)),
      ],
    ]);
  }
}

// Campo de texto de las pantallas de acceso, con la etiqueta arriba.
class AuthField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? type;
  final bool password;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.type,
    this.password = false,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.formatters,
    this.validator,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.label != null) ...[
        Text(
          '${widget.label!.toUpperCase()} *',
          style: const TextStyle(
              color: Colors.white60, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
      ],
      TextFormField(
        controller: widget.controller,
        keyboardType: widget.type,
        obscureText: widget.password && _oculta,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        inputFormatters: widget.formatters,
        validator: widget.validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hint,
          suffixIcon: widget.password
              ? IconButton(
                  icon: Icon(_oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.white54),
                  onPressed: () => setState(() => _oculta = !_oculta),
                )
              : widget.suffixIcon,
        ),
      ),
    ]);
  }
}

// Mensaje de error en rojo, dentro del formulario.
class AuthBanner extends StatelessWidget {
  final String texto;
  const AuthBanner(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rojo.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rojo.withAlpha(120)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.rojo, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: const TextStyle(color: Colors.white))),
      ]),
    );
  }
}

// Boton "< Volver" de las pantallas de acceso.
class AuthBack extends StatelessWidget {
  const AuthBack({super.key});
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: Colors.white60, padding: EdgeInsets.zero),
      onPressed: () => Navigator.maybePop(context),
      icon: const Icon(Icons.chevron_left),
      label: const Text('Volver'),
    );
  }
}
