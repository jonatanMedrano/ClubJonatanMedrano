import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/stores.dart';

/// "¡RESERVA CONFIRMADA!" y, a los 2 segundos, lleva a Mis reservas.
class ReservaConfirmadaScreen extends StatefulWidget {
  const ReservaConfirmadaScreen({super.key});
  @override
  State<ReservaConfirmadaScreen> createState() => _ReservaConfirmadaScreenState();
}

class _ReservaConfirmadaScreenState extends State<ReservaConfirmadaScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      NavController.tab.value = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(Brightness.dark),
      child: Builder(
        builder: (context) {
          final estilo = tituloStyle(context, size: 44, color: Colors.white);
          return PopScope(
            canPop: false,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: AppColors.verdeNoche,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.check_rounded, size: 64, color: Colors.black),
                  ),
                  const SizedBox(height: 30),
                  Text('¡RESERVA', style: estilo),
                  const SizedBox(height: 6),
                  Text('CONFIRMADA!',
                      style: estilo.copyWith(color: AppColors.verdeNoche)),
                  const SizedBox(height: 16),
                  const Text('Redirigiendo a tus reservas...',
                      style: TextStyle(color: Colors.white54)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
