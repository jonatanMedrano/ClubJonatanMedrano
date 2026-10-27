import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../models/models.dart';

// "RamosMejia" -> "RamosMejia", "Futbol 5" -> "Futbol5"
String pascal(String s) => norm(s)
    .split(RegExp(r'[^a-z0-9]+'))
    .where((p) => p.isNotEmpty)
    .map((p) => p[0].toUpperCase() + p.substring(1))
    .join();

// Hora "08:00" -> 8
int horaDe(String hhmm) => int.tryParse(hhmm.split(':').first) ?? 8;

// abre un formulario en una hoja que sube desde abajo, devuelve true si se guardo algo
Future<bool?> mostrarFormulario(BuildContext context, Widget form) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.superficie,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: form,
    ),
  );
}

// Estructura comun de los formularios: titulo, campos, error y boton guardar.
class FormSheet extends StatelessWidget {
  final String titulo;
  final List<Widget> children;
  final VoidCallback onGuardar;
  final bool guardando;
  final String? error;
  final GlobalKey<FormState> formKey;

  const FormSheet({
    super.key,
    required this.titulo,
    required this.children,
    required this.onGuardar,
    required this.formKey,
    this.guardando = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(titulo.toUpperCase(), style: tituloStyle(context, size: 28)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 12),
            for (final c in children)
              Padding(padding: const EdgeInsets.only(bottom: 14), child: c),
            if (error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.rojo.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.rojo.withAlpha(120)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.rojo, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(error!)),
                ]),
              ),
            FilledButton(
              onPressed: guardando ? null : onGuardar,
              child: guardando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }
}

// Lista desplegable con el mismo aspecto que un campo de texto.
class CampoSelect<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const CampoSelect({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      isEmpty: value == null,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Selector de hora en punto (00:00 a 23:00).
class CampoHora extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const CampoHora({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CampoSelect<int>(
      label: label,
      value: value,
      items: [
        for (var h = 0; h < 24; h++)
          DropdownMenuItem(value: h, child: Text('${two(h)}:00')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// Tarjeta de un elemento de la lista, con botones de editar y eliminar.
class AdminItem extends StatelessWidget {
  final String emoji, titulo;
  final String? subtitulo, detalle;
  final VoidCallback onEditar, onEliminar;

  const AdminItem({
    super.key,
    required this.emoji,
    required this.titulo,
    required this.onEditar,
    required this.onEliminar,
    this.subtitulo,
    this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: context.chipBg, borderRadius: BorderRadius.circular(14)),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(subtitulo!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.muted, fontSize: 13)),
            ],
            if (detalle != null) ...[
              const SizedBox(height: 2),
              Text(detalle!, style: TextStyle(color: context.muted, fontSize: 12)),
            ],
          ]),
        ),
        IconButton(
          tooltip: 'Editar',
          icon: Icon(Icons.edit_outlined, color: context.verde),
          onPressed: onEditar,
        ),
        IconButton(
          tooltip: 'Eliminar',
          icon: const Icon(Icons.delete_outline, color: AppColors.rojo),
          onPressed: onEliminar,
        ),
      ]),
    );
  }
}

// Pantalla de lista con boton "Agregar" (base de las tres gestiones).
class AdminListaScaffold extends StatelessWidget {
  final String blanco, verde, textoAgregar, vacio;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onAgregar;
  final Widget? filtros;
  final List<Widget> items;

  const AdminListaScaffold({
    super.key,
    required this.blanco,
    required this.verde,
    required this.textoAgregar,
    required this.vacio,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onAgregar,
    required this.items,
    this.filtros,
  });

  @override
  Widget build(BuildContext context) {
    Widget cuerpo;
    if (loading) {
      cuerpo = const EstadoCarga();
    } else if (error != null) {
      cuerpo = EstadoError(error!, onRetry: () {
        onRefresh();
      });
    } else if (items.isEmpty) {
      cuerpo = EstadoVacio(vacio);
    } else {
      cuerpo = Column(children: [
        for (final w in items) Padding(padding: const EdgeInsets.only(bottom: 12), child: w),
      ]);
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAgregar,
        backgroundColor: context.verde,
        foregroundColor: context.onVerde,
        icon: const Icon(Icons.add),
        label: Text(textoAgregar,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
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
              TituloPantalla(blanco, verde),
              const SizedBox(height: 14),
              if (filtros != null) ...[filtros!, const SizedBox(height: 14)],
              cuerpo,
            ],
          ),
        ),
      ),
    );
  }
}
