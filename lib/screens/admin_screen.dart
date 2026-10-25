import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import 'admin_canchas_screen.dart';
import 'admin_deportes_screen.dart';
import 'admin_sedes_screen.dart';

/// Panel del administrador: tres accesos a las gestiones.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _ir(BuildContext context, Widget pantalla) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: context.muted, padding: EdgeInsets.zero),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Volver'),
              ),
            ),
            const TituloPantalla('Gestión', 'Admin'),
            const SizedBox(height: 6),
            Text('Agregá, modificá o eliminá los datos del club.',
                style: TextStyle(color: context.muted)),
            const SizedBox(height: 22),
            _Opcion(
              emoji: '🏢',
              titulo: 'Gestión de sedes',
              detalle: 'Nombre, dirección y horario de cada sede',
              onTap: () => _ir(context, const AdminSedesScreen()),
            ),
            const SizedBox(height: 14),
            _Opcion(
              emoji: '🏟️',
              titulo: 'Gestión de canchas',
              detalle: 'Precio, tipo, iluminación y horarios',
              onTap: () => _ir(context, const AdminCanchasScreen()),
            ),
            const SizedBox(height: 14),
            _Opcion(
              emoji: '🏅',
              titulo: 'Gestión de deportes',
              detalle: 'Fútbol, tenis, hockey, vóley, golf...',
              onTap: () => _ir(context, const AdminDeportesScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  final String emoji, titulo, detalle;
  final VoidCallback onTap;
  const _Opcion({
    required this.emoji,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: context.verde.withAlpha(35),
              borderRadius: BorderRadius.circular(16)),
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo.toUpperCase(), style: tituloStyle(context, size: 24)),
            const SizedBox(height: 4),
            Text(detalle, style: TextStyle(color: context.muted, fontSize: 13)),
          ]),
        ),
        Icon(Icons.chevron_right, color: context.muted),
      ]),
    );
  }
}
