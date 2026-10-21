import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ReservarScreen extends StatefulWidget {
  final Espacio espacio;
  const ReservarScreen({super.key, required this.espacio});
  @override
  State<ReservarScreen> createState() => _ReservarScreenState();
}

class _ReservarScreenState extends State<ReservarScreen> {
  DateTime fecha = DateTime.now();
  List<int> libres = [];
  int? inicio;
  int duracion = 1;
  bool loading = true, saving = false;
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
      inicio = null;
    });
    try {
      libres = await Api.horasLibres(widget.espacio.id, isoDate(fecha));
    } catch (e) {
      error = errorMessage(e);
    }
    if (mounted) setState(() => loading = false);
  }

  List<int> get _validos =>
      libres.where((h) => duracion == 1 || libres.contains(h + 1)).toList();

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) {
      fecha = d;
      _cargar();
    }
  }

  Future<void> _reservar() async {
    setState(() => saving = true);
    try {
      await Api.crearReserva(widget.espacio.id, isoDate(fecha),
          '${two(inicio!)}:00', '${two(inicio! + duracion)}:00');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showMsg(context, errorMessage(e), error: true);
        _cargar(); // por si alguien ocupó el horario
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.espacio;
    return Scaffold(
      appBar: AppBar(title: Text(e.nombre, style: const TextStyle(fontSize: 16))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('${e.sede} • ${e.indoor ? 'Indoor' : 'Outdoor'} • \$${e.precioHora.toStringAsFixed(0)}/h'),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(fmtDate(isoDate(fecha))),
            trailing: TextButton(onPressed: _elegirFecha, child: const Text('Cambiar')),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Duración', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1 hora')),
            ButtonSegment(value: 2, label: Text('2 horas')),
          ],
          selected: {duracion},
          onSelectionChanged: (s) => setState(() {
            duracion = s.first;
            if (inicio != null && !_validos.contains(inicio)) inicio = null;
          }),
        ),
        const SizedBox(height: 16),
        const Text('Horarios disponibles', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (error != null)
          Column(children: [
            Text(error!),
            TextButton(onPressed: _cargar, child: const Text('Reintentar')),
          ])
        else if (_validos.isEmpty)
          const Text('No hay horarios disponibles para ese día.')
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final h in _validos)
              ChoiceChip(
                label: Text('${two(h)}:00'),
                selected: inicio == h,
                onSelected: (_) => setState(() => inicio = h),
              ),
          ]),
        const SizedBox(height: 24),
        if (inicio != null) ...[
          Text('${two(inicio!)}:00 a ${two(inicio! + duracion)}:00 hs',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Total: \$${(e.precioHora * duracion).toStringAsFixed(0)}',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: (inicio == null || saving) ? null : _reservar,
          child: saving
              ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirmar reserva'),
        ),
      ]),
    );
  }
}
