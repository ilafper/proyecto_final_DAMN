import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Barra de navegación modular con estética deportiva sobria y moderna (estilo Playtomic).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
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
    final List<NavigationDestination> destinations = isAdmin
        ? const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.accent, size: 24),
              label: 'Club',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline_rounded, size: 22),
              selectedIcon: Icon(Icons.add_circle_rounded, color: AppTheme.accent, size: 24),
              label: 'Crear Pista',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined, size: 22),
              selectedIcon: Icon(Icons.group_rounded, color: AppTheme.accent, size: 24),
              label: 'Socios',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined, size: 22),
              selectedIcon: Icon(Icons.event_available_rounded, color: AppTheme.accent, size: 24),
              label: 'Reservas',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined, size: 22),
              selectedIcon: Icon(Icons.tune_rounded, color: AppTheme.accent, size: 24),
              label: 'Ajustes',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined, size: 24),
              selectedIcon: Icon(Icons.explore_rounded, color: AppTheme.accent, size: 26),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined, size: 22),
              selectedIcon: Icon(Icons.confirmation_number_rounded, color: AppTheme.accent, size: 24),
              label: 'Mis Reservas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, size: 24),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.accent, size: 26),
              label: 'Perfil',
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppTheme.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 64,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.accentBg,
          selectedIndex: currentIndex.clamp(0, destinations.length - 1),
          onDestinationSelected: onTap,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: destinations,
        ),
      ),
    );
  }
}
