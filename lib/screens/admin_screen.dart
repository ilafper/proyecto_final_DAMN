import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import 'auth_screen.dart';

// Vistas modulares de cada pestaña de Admin
import 'admin/admin_home_view.dart';
import 'admin/admin_crear_evento_view.dart';
import 'admin/admin_usuarios_view.dart';
import 'admin/admin_gestionar_view.dart';
import 'admin/admin_ajustes_view.dart';

class AdminScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const AdminScreen({super.key, required this.usuario});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final String nombre = widget.usuario['nombre'] ?? widget.usuario['nombre_completo'] ?? 'Administrador';
    final String email = widget.usuario['email'] ?? '';
    final String rol = (widget.usuario['rol'] ?? 'admin').toString().toUpperCase();

    final List<String> titulos = [
      'PANEL DEL CLUB',
      'PISTAS Y ESPACIOS',
      'SOCIOS DEL CLUB',
      'RESERVAS DE PISTAS',
      'AJUSTES DEL CLUB',
    ];

    final List<Widget> vistas = [
      AdminHomeView(nombre: nombre, email: email, rol: rol),
      const AdminCrearEventoView(),
      const AdminUsuariosView(),
      const AdminGestionarView(),
      AdminAjustesView(nombre: nombre, email: email, rol: rol),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              titulos[_currentIndex],
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: vistas[_currentIndex],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        rol: 'admin',
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
