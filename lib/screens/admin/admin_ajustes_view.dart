import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AdminAjustesView extends StatelessWidget {
  final String nombre;
  final String email;
  final String rol;

  const AdminAjustesView({
    super.key,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'ajustes',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

