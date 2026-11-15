import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AdminUsuariosView extends StatefulWidget {
  const AdminUsuariosView({super.key});

  @override
  State<AdminUsuariosView> createState() => _AdminUsuariosViewState();
}

class _AdminUsuariosViewState extends State<AdminUsuariosView> {
  final List<Map<String, dynamic>> _usuarios = [];
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    if (_usuarios.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: _cargarUsuarios,
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group_outlined, size: 52, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Directorio de Socios',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Los socios y jugadores registrados en la plataforma se sincronizarán en este listado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _cargarUsuarios,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _usuarios.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final u = _usuarios[index];
          final nombre = u['nombre'] ?? 'Socio';
          final email = u['email'] ?? '';
          final rol = (u['rol'] ?? 'cliente').toString().toUpperCase();
          final bool esAdmin = rol == 'ADMIN';

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, width: 1.2),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: esAdmin ? AppTheme.energyBg : AppTheme.accentBg,
                child: Icon(
                  esAdmin ? Icons.shield_rounded : Icons.person_rounded,
                  color: esAdmin ? AppTheme.energy : AppTheme.accent,
                ),
              ),
              title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              subtitle: Text(email, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: esAdmin ? AppTheme.energyBg : AppTheme.accentBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rol,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: esAdmin ? AppTheme.energy : AppTheme.accent,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
