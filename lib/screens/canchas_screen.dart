import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'reservar_screen.dart';

class CanchasScreen extends StatefulWidget {
  final VoidCallback onReserved;
  const CanchasScreen({super.key, required this.onReserved});
  @override
  State<CanchasScreen> createState() => _CanchasScreenState();
}

class _CanchasScreenState extends State<CanchasScreen> {
  List<Sede> sedes = [];
  List<Deporte> deportes = [];
  List<Espacio> espacios = [];
  int? sedeId, deporteId;
  bool loading = true, primera = true;
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
      if (primera) {
        final r = await Future.wait([Api.sedes(), Api.deportes()]);
        sedes = r[0] as List<Sede>;
        deportes = r[1] as List<Deporte>;
        // Por defecto mostramos Fútbol.
        final f = deportes.where((d) => d.nombre.toLowerCase().startsWith('f'));
        if (f.isNotEmpty) deporteId = f.first.id;
        primera = false;
      }
      espacios = await Api.espacios(sedeId: sedeId, deporteId: deporteId);
    } catch (e) {
      error = errorMessage(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Widget _chips(String todas, Map<int, String> items, int? sel,
      void Function(int?) onSel) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
                label: Text(todas), selected: sel == null, onSelected: (_) => onSel(null)),
          ),
          for (final e in items.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                  label: Text(e.value),
                  selected: sel == e.key,
                  onSelected: (_) => onSel(e.key)),
            ),
        ],
      ),
    );
  }

  Future<void> _abrir(Espacio e) async {
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => ReservarScreen(espacio: e)));
    if (ok == true) {
      widget.onReserved();
      messengerKeyMsg();
    }
  }

  void messengerKeyMsg() => showMsg(context, '¡Reserva confirmada!');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservá tu cancha')),
      body: Column(children: [
        const SizedBox(height: 8),
        _chips('Todas las sedes', {for (final s in sedes) s.id: s.nombre}, sedeId,
            (v) {
          sedeId = v;
          _cargar();
        }),
        _chips('Todos los deportes', {for (final d in deportes) d.id: d.nombre},
            deporteId, (v) {
          deporteId = v;
          _cargar();
        }),
        Expanded(child: _contenido()),
      ]),
    );
  }

  Widget _contenido() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(error!, textAlign: TextAlign.center),
          TextButton(onPressed: _cargar, child: const Text('Reintentar')),
        ]),
      );
    }
    if (espacios.isEmpty) {
      return const Center(child: Text('No hay canchas con esos filtros.'));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: espacios.length,
        itemBuilder: (_, i) {
          final e = espacios[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => _abrir(e),
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.sports_soccer, color: Colors.white),
              ),
              title: Text(e.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  '${e.sede} • ${e.indoor ? 'Indoor' : 'Outdoor'}\n${e.apertura} a ${e.cierre} hs'),
              isThreeLine: true,
              trailing: Text('\$${e.precioHora.toStringAsFixed(0)}/h',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          );
        },
      ),
    );
  }
}
