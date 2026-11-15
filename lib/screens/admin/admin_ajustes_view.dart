import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../auth_screen.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta Administrador
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border, width: 1.2),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.shield_rounded, color: AppTheme.accentLight, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Configuración del Club',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, width: 1.2),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.access_time_rounded,
                  title: 'Horario del Club',
                  subtitle: 'Lunes a Domingo: 09:00 - 21:00',
                ),
                const Divider(height: 1, color: AppTheme.border),
                _buildSettingTile(
                  icon: Icons.sports_tennis_rounded,
                  title: 'Duración de Sesiones',
                  subtitle: '90 minutos por reserva',
                ),
                const Divider(height: 1, color: AppTheme.border),
                _buildSettingTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Avisos de Nuevas Reservas',
                  subtitle: 'Notificaciones push inmediatas',
                ),
                const Divider(height: 1, color: AppTheme.border),
                _buildSettingTile(
                  icon: Icons.euro_rounded,
                  title: 'Moneda y Facturación',
                  subtitle: 'EUR (€) • IVA incluido',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
              icon: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 18),
              label: const Text(
                'Cerrar Sesión de Administrador',
                style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textMuted),
    );
  }
}
