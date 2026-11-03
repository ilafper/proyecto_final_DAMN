import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Barra de navegación modular adaptable al ROL del usuario (Admin o Cliente).
class AppBottomNav extends StatelessWidget {
  /// Índice de la pestaña seleccionada actualmente.
  final int currentIndex;

  /// Callback que se dispara al pulsar una pestaña.
  final ValueChanged<int> onTap;

  /// Rol del usuario: 'admin', 'cliente', etc.
  final String rol;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.rol = 'cliente',
  });

  bool get isAdmin => rol.toLowerCase() == 'admin';

  @override
  Widget build(BuildContext context) {
    // Definimos las pestañas segun el rol
    final List<NavigationDestination> destinations = isAdmin
        ? const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.accent),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline_rounded),
              selectedIcon: Icon(Icons.add_circle_rounded, color: AppTheme.accent),
              label: 'Eventos',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded, color: AppTheme.accent),
              label: 'Usuarios',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded, color: AppTheme.accent),
              label: 'Gestionar',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: AppTheme.accent),
              label: 'Ajustes',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded, color: AppTheme.accent),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded, color: AppTheme.accent),
              label: 'Mis Citas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.accent),
              label: 'Perfil',
            ),
          ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: NavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.accent.withValues(alpha: 0.12),
        selectedIndex: currentIndex.clamp(0, destinations.length - 1),
        onDestinationSelected: onTap,
        destinations: destinations,
      ),
    );
  }
}
