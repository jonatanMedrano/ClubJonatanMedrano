import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/stores.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});
  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  int _tab = 0; // 0 próximas, 1 historial

  Future<void> _cancelar(Reserva r) async {
    final ok = await confirmarPeligro(
      context,
      titulo: 'Cancelar reserva',
      mensaje:
          '¿Cancelar ${r.espacio} el ${fmtDate(r.fecha)} de ${r.inicio} a ${r.fin}? '
          'El horario volverá a estar disponible para otras personas.',
      textoOk: 'Cancelar reserva',
    );
    if (!ok || !mounted) return;
    try {
      await Api.cancelarReserva(r.id);
      if (mounted) showMsg(context, 'Reserva cancelada.');
      await ReservasStore.instance.load(silent: true);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReservasStore.instance,
      builder: (context, _) {
        final rs = ReservasStore.instance;
        final proximas = rs.proximas;
        final historial = rs.historial;
        final lista = _tab == 0 ? proximas : historial;

        Widget cuerpo;
        if (rs.loading && !rs.loaded) {
          cuerpo = const EstadoCarga();
        } else if (rs.error != null && !rs.loaded) {
          cuerpo = EstadoError(rs.error!, onRetry: rs.load);
        } else if (lista.isEmpty) {
          cuerpo = EstadoVacio(
            _tab == 0 ? 'No tenés reservas próximas.' : 'Todavía no tenés historial.',
            emoji: '📅',
          );
        } else {
          cuerpo = Column(children: [
            for (final r in lista)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ReservaCard(
                  reserva: r,
                  onCancelar: r.proxima ? () => _cancelar(r) : null,
                ),
              ),
          ]);
        }

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: rs.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  const TituloPantalla('Mis', 'Reservas'),
                  const SizedBox(height: 6),
                  Text('${proximas.length} activas · ${historial.length} historial',
                      style: TextStyle(color: context.muted)),
                  const SizedBox(height: 18),
                  _Pestanas(
                    tab: _tab,
                    proximas: proximas.length,
                    onChanged: (v) => setState(() => _tab = v),
                  ),
                  const SizedBox(height: 18),
                  cuerpo,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Pestanas extends StatelessWidget {
  final int tab, proximas;
  final ValueChanged<int> onChanged;
  const _Pestanas({required this.tab, required this.proximas, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget item(int i, String texto) {
      final sel = tab == i;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sel ? context.verde : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(texto,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: sel ? context.onVerde : context.muted)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.chipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borde),
      ),
      child: Row(children: [
        item(0, 'Próximas ($proximas)'),
        item(1, 'Historial'),
      ]),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final Reserva reserva;
  final VoidCallback? onCancelar;
  const _ReservaCard({required this.reserva, this.onCancelar});

  @override
  Widget build(BuildContext context) {
    final r = reserva;
    final color = r.cancelada ? AppColors.rojo : context.verde;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: context.chipBg, borderRadius: BorderRadius.circular(14)),
            child: Text(deporteEmoji(r.espacio), style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text('Sede ${r.sede}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                Tag(r.estadoLabel, color: color),
              ]),
              const SizedBox(height: 3),
              Text(r.espacio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mono(context.muted, size: 10)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: context.muted),
                const SizedBox(width: 5),
                Text(fmtCortoIso(r.fecha),
                    style: TextStyle(color: context.muted, fontSize: 13)),
                const SizedBox(width: 14),
                Icon(Icons.schedule, size: 14, color: context.muted),
                const SizedBox(width: 5),
                Text('${r.inicio} – ${r.fin}',
                    style: TextStyle(color: context.muted, fontSize: 13)),
              ]),
            ]),
          ),
        ]),
        Divider(height: 24, color: context.borde),
        Row(children: [
          Expanded(
            child: Text(fmtPrecio(r.total),
                style: tituloStyle(context, size: 24, color: context.verde)),
          ),
          if (onCancelar != null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rojo,
                side: BorderSide(color: AppColors.rojo.withAlpha(120)),
              ),
              onPressed: onCancelar,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancelar'),
            ),
        ]),
      ]),
    );
  }
}
