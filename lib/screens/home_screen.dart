import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'canchas_screen.dart';
import 'perfil_screen.dart';
import 'reservas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    NotificationService.init();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CanchasScreen(onReserved: () => setState(() => _i = 1)),
      const ReservasScreen(),
      const PerfilScreen(),
    ];
    return Scaffold(
      body: pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sports_soccer), label: 'Canchas'),
          NavigationDestination(icon: Icon(Icons.event_note), label: 'Mis reservas'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
