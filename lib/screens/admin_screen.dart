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
      'Panel de Control',
      'Crear Evento / Espacio',
      'Directorio de Usuarios',
      'Gestión de Reservas',
      'Ajustes del Sistema',
    ];

    // Cada pestaña en su archivo independiente
    final List<Widget> vistas = [
      AdminHomeView(nombre: nombre, email: email, rol: rol),
      const AdminCrearEventoView(),
      const AdminUsuariosView(),
      const AdminGestionarView(),
      AdminAjustesView(nombre: nombre, email: email, rol: rol),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titulos[_currentIndex]),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
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
