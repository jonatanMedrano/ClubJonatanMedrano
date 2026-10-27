import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/notification_service.dart';
import '../services/stores.dart';
import 'inicio_screen.dart';
import 'perfil_screen.dart';
import 'reservas_screen.dart';
import 'sedes_screen.dart';

// pantalla principal con las 4 pestanas (inicio, sedes, reservas, perfil) dentro de un IndexedStack, asi cada
// una conserva su estado al cambiar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    NavController.tab.value = 0;
    // Se carga despues del primer dibujo para no avisar cambios en pleno armado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserStore.instance.load();
      CatalogStore.instance.load();
      ReservasStore.instance.load();
      NotificationStore.instance.load();
      NotificationService.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NavController.tab,
      // el boton atras vuelve primero a la pestana de inicio y recien despues cierra la app
      builder: (context, i, _) => PopScope(
        canPop: i == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) NavController.tab.value = 0;
        },
        child: Scaffold(
          body: IndexedStack(index: i, children: const [
            InicioScreen(),
            SedesScreen(),
            ReservasScreen(),
            PerfilScreen(),
          ]),
          bottomNavigationBar: _NavBar(
            index: i,
            onTap: (v) => NavController.tab.value = v,
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavBar({required this.index, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Inicio'),
    (Icons.domain_outlined, Icons.domain, 'Sedes'),
    (Icons.event_note_outlined, Icons.event_note, 'Reservas'),
    (Icons.person_outline, Icons.person, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: context.superficie,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.borde),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icono: index == i ? _items[i].$2 : _items[i].$1,
                    label: _items[i].$3,
                    activo: index == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icono;
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _NavItem({
    required this.icono,
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo ? context.verde : context.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, color: color, size: 24),
        const SizedBox(height: 3),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 3,
          width: activo ? 22 : 0,
          decoration: BoxDecoration(
              color: context.verde, borderRadius: BorderRadius.circular(2)),
        ),
      ]),
    );
  }
}
