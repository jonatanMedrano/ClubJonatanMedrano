import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/stores.dart';

/// Cuadro emergente con el historial de avisos (la campana del inicio).
Future<void> mostrarNotificaciones(BuildContext context) {
  // Guardamos cómo estaban (leídas / sin leer) antes de marcarlas.
  final items = List<AppNotif>.of(NotificationStore.instance.items);
  NotificationStore.instance.marcarLeidas();

  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: ctx.superficie,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Expanded(
                child: Text('Notificaciones',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ]),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text('Todavía no tenés notificaciones.',
                    style: TextStyle(color: ctx.muted)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _Item(items[i]),
                ),
              ),
          ]),
        ),
      ),
    ),
  );
}

class _Item extends StatelessWidget {
  final AppNotif n;
  const _Item(this.n);

  @override
  Widget build(BuildContext context) {
    final f = n.fecha;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.chipBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: n.leida ? context.muted : context.verde,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (n.cuerpo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(n.cuerpo, style: const TextStyle(height: 1.3)),
            ],
            const SizedBox(height: 4),
            Text('${fmtCorto(f)} · ${two(f.hour)}:${two(f.minute)}',
                style: TextStyle(color: context.muted, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}
