import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});
  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  List<Reserva> items = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      items = await Api.misReservas();
    } catch (e) {
      error = errorMessage(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _cancelar(Reserva r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text('¿Cancelar ${r.espacio} el ${fmtDate(r.fecha)} de ${r.inicio} a ${r.fin}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.cancelarReserva(r.id);
      if (mounted) showMsg(context, 'Reserva cancelada.');
      _cargar();
    } catch (e) {
      if (mounted) showMsg(context, errorMessage(e), error: true);
    }
  }

  int _cmp(Reserva a, Reserva b) =>
      '${a.fecha}${a.inicio}'.compareTo('${b.fecha}${b.inicio}');

  @override
  Widget build(BuildContext context) {
    final proximas = items.where((r) => r.proxima).toList()..sort(_cmp);
    final historial = items.where((r) => !r.proxima).toList()
      ..sort((a, b) => _cmp(b, a));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis reservas'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Próximas'), Tab(text: 'Historial')],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(error!, textAlign: TextAlign.center),
                      TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                    ]),
                  )
                : TabBarView(children: [
                    _lista(proximas, 'No tenés reservas próximas.', true),
                    _lista(historial, 'Todavía no tenés historial.', false),
                  ]),
      ),
    );
  }

  Widget _lista(List<Reserva> lista, String vacio, bool puedeCancelar) {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: lista.isEmpty
          ? ListView(children: [
              Padding(padding: const EdgeInsets.all(48), child: Center(child: Text(vacio)))
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final r = lista[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                            child: Text(r.espacio,
                                style: const TextStyle(fontWeight: FontWeight.w600))),
                        Chip(
                          label: Text(r.cancelada ? 'Cancelada' : (r.proxima ? 'Confirmada' : 'Finalizada')),
                          visualDensity: VisualDensity.compact,
                        ),
                      ]),
                      Text(r.sede),
                      Text('${fmtDate(r.fecha)} • ${r.inicio} a ${r.fin} hs'),
                      Text('Total: \$${r.total.toStringAsFixed(0)}'),
                      if (puedeCancelar)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: () => _cancelar(r),
                              child: const Text('Cancelar reserva')),
                        ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
