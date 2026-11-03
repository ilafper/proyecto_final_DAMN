import 'package:flutter/material.dart';
import '../../services/bbdd_service.dart';
import '../../theme/app_theme.dart';

class AdminGestionarView extends StatefulWidget {
  const AdminGestionarView({super.key});

  @override
  State<AdminGestionarView> createState() => _AdminGestionarViewState();
}

class _AdminGestionarViewState extends State<AdminGestionarView> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _reservas = [];
  bool _cargando = true;
  final Set<dynamic> _procesandoIds = {};

  @override
  void initState() {
    super.initState();
    _cargarReservas();
  }

  Future<void> _cargarReservas() async {
    setState(() => _cargando = true);
    final lista = await _authService.getReservas();
    if (mounted) {
      setState(() {
        _reservas = lista;
        _cargando = false;
      });
    }
  }

  // Cambiar estado a 'reservado' o 'rechazado'
  Future<void> _cambiarEstado(dynamic reservaId, String nuevoEstado) async {
    setState(() => _procesandoIds.add(reservaId));

    final respuesta = await _authService.actualizarEstadoReserva(
      reservaId: reservaId,
      nuevoEstado: nuevoEstado,
    );

    setState(() => _procesandoIds.remove(reservaId));

    if (!mounted) return;

    if (respuesta['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['mensaje'] ?? 'Estado actualizado a $nuevoEstado'),
          backgroundColor: nuevoEstado == 'reservado' ? AppTheme.success : AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Recargar lista de reservas
      _cargarReservas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['mensaje'] ?? 'Error al actualizar estado'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _colorPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'reservado':
      case 'confirmada':
        return AppTheme.success; // Verde
      case 'rechazado':
      case 'cancelada':
        return AppTheme.danger; // Rojo
      case 'pendiente':
        return AppTheme.warning; // Naranja
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarReservas,
      child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _reservas.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.calendar_month_outlined, size: 56, color: AppTheme.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'No hay reservas registradas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Cuando los usuarios reserven desde la aplicación aparecerán aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: _reservas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = _reservas[index];
                    final reservaId = r['id'];
                    final lugar = r['espacio_nombre'] ?? 'Espacio #${r['evento_id'] ?? r['espacio_id']}';
                    final usuario = r['usuario_nombre'] ?? r['usuario_email'] ?? 'Usuario #${r['usuario_id']}';
                    final fecha = (r['fecha'] ?? r['fecha_inicio'] ?? '').toString().split('T').first;
                    final franja = r['franja_horaria'] ?? '';
                    final estado = (r['estado'] ?? 'pendiente').toString();
                    final colorEstado = _colorPorEstado(estado);
                    final estaProcesando = _procesandoIds.contains(reservaId);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fila de encabezado: Espacio y Etiqueta de Estado
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lugar,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorEstado.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    estado.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorEstado,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Solicitado por: $usuario', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            const SizedBox(height: 8),

                            // Fecha y hora
                            Row(
                              children: [
                                const Icon(Icons.date_range_rounded, size: 15, color: AppTheme.textMuted),
                                const SizedBox(width: 5),
                                Text(fecha, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                                if (franja.isNotEmpty) ...[
                                  const SizedBox(width: 14),
                                  const Icon(Icons.access_time_rounded, size: 15, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Text(franja, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                                ],
                              ],
                            ),

                            const SizedBox(height: 14),
                            const Divider(height: 1, color: AppTheme.border),
                            const SizedBox(height: 12),

                            // BOTONES DE ACEPTAR Y RECHAZAR
                            if (estaProcesando)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  // Botón Rechazar (Neutro, sobrio con sutil toque muted)
                                  Expanded(
                                    child: SizedBox(
                                      height: 38,
                                      child: OutlinedButton(
                                        onPressed: () => _cambiarEstado(reservaId, 'rechazado'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.textSecondary,
                                          backgroundColor: Colors.transparent,
                                          side: const BorderSide(color: AppTheme.border, width: 1.2),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.close_rounded, size: 15, color: AppTheme.textSecondary),
                                            SizedBox(width: 6),
                                            Text(
                                              'Rechazar',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Botón Aceptar (Elegante Slate/Dark Primary)
                                  Expanded(
                                    child: SizedBox(
                                      height: 38,
                                      child: ElevatedButton(
                                        onPressed: () => _cambiarEstado(reservaId, 'reservado'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_rounded, size: 15, color: Colors.white),
                                            SizedBox(width: 6),
                                            Text(
                                              'Aprobar',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
