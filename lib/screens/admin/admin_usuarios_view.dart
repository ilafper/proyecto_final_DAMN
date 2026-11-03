import 'package:flutter/material.dart';
import '../../services/bbdd_service.dart';
import '../../theme/app_theme.dart';

class AdminUsuariosView extends StatefulWidget {
  const AdminUsuariosView({super.key});

  @override
  State<AdminUsuariosView> createState() => _AdminUsuariosViewState();
}

class _AdminUsuariosViewState extends State<AdminUsuariosView> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    // Nota: Si aún no tienes el endpoint /api/usuarios en el backend,
    // devolverá lista vacía sin inventar ningún dato falso.
    if (mounted) {
      setState(() {
        _usuarios = [];
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usuarios.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarUsuarios,
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.people_outline_rounded, size: 56, color: AppTheme.textMuted),
                SizedBox(height: 16),
                Text(
                  'No hay usuarios para mostrar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Cuando crees el endpoint de usuarios en el servidor, aquí se mostrarán los datos reales de la base de datos.',
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
      onRefresh: _cargarUsuarios,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _usuarios.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final u = _usuarios[index];
          final nombre = u['nombre'] ?? 'Sin nombre';
          final email = u['email'] ?? '';
          final rol = (u['rol'] ?? 'cliente').toString().toUpperCase();
          final bool esAdmin = rol == 'ADMIN';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: esAdmin ? Colors.amber.shade100 : Colors.blue.shade50,
                child: Icon(
                  esAdmin ? Icons.shield_rounded : Icons.person_rounded,
                  color: esAdmin ? Colors.orange.shade800 : Colors.blue,
                ),
              ),
              title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(email),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: esAdmin ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rol,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: esAdmin ? Colors.orange.shade900 : Colors.green.shade800,
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
