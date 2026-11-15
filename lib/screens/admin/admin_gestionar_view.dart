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
  String _filtroEstado = 'Todas';

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

  List<Map<String, dynamic>> get _reservasFiltradas {
    if (_filtroEstado == 'Todas') return _reservas;
    return _reservas.where((r) {
      final estado = (r['estado'] ?? '').toString().toLowerCase();
      if (_filtroEstado == 'Confirmadas') {
        return estado == 'confirmada' || estado == 'reservado';
      }
      if (_filtroEstado == 'Lista de Espera') {
        return estado == 'en_espera' || estado == 'pendiente';
      }
      if (_filtroEstado == 'Canceladas') {
        return estado == 'cancelada' || estado == 'rechazado';
      }
      return true;
    }).toList();
  }

  Future<void> _cancelarReservaAdmin(dynamic reservaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar reserva?'),
        content: const Text(
          'Esta acción liberará la pista. Si hay usuarios en lista de espera, se asignará automáticamente al siguiente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _authService.cancelarReserva(reservaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['mensaje'] ?? 'Reserva cancelada'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _cargarReservas();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _reservasFiltradas;
    final totalConfirmadas = _reservas.where((r) {
      final e = (r['estado'] ?? '').toString().toLowerCase();
      return e == 'confirmada' || e == 'reservado';
    }).length;
    final totalEspera = _reservas.where((r) {
      final e = (r['estado'] ?? '').toString().toLowerCase();
      return e == 'en_espera' || e == 'pendiente';
    }).length;

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _cargarReservas,
      child: Column(
        children: [
          // Barra de filtros por estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todas', _reservas.length, AppTheme.primary),
                  const SizedBox(width: 8),
                  _buildFilterChip('Confirmadas', totalConfirmadas, AppTheme.success),
                  const SizedBox(width: 8),
                  _buildFilterChip('Lista de Espera', totalEspera, AppTheme.warning),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Canceladas',
                    _reservas.length - totalConfirmadas - totalEspera,
                    AppTheme.danger,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Lista de reservas
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : filtradas.isEmpty
                    ? Center(
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
                                child: const Icon(
                                  Icons.event_available_rounded,
                                  size: 48,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _filtroEstado == 'Todas'
                                    ? 'No hay reservas registradas'
                                    : 'No hay reservas en "$_filtroEstado"',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Las reservas confirmadas directamente y listas de espera aparecerán aquí.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtradas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final r = filtradas[index];
                          final reservaId = r['id'];
                          final lugar = r['espacio_nombre'] ?? 'Pista / Espacio #${r['evento_id'] ?? r['espacio_id']}';
                          final usuario = r['usuario_nombre'] ?? r['usuario_email'] ?? 'Socio #${r['usuario_id']}';
                          final email = r['usuario_email'] ?? '';
                          final fecha = (r['fecha'] ?? r['fecha_inicio'] ?? '').toString().split('T').first;
                          final franja = r['franja_horaria'] ?? '09:00 - 10:30';
                          final estado = (r['estado'] ?? 'confirmada').toString().toLowerCase();

                          Color statusColor = AppTheme.success;
                          Color statusBg = const Color(0xFFDCFCE7);
                          String statusText = 'CONFIRMADA';
                          IconData statusIcon = Icons.check_circle_rounded;

                          if (estado == 'en_espera' || estado == 'pendiente') {
                            statusColor = AppTheme.warning;
                            statusBg = const Color(0xFFFEF3C7);
                            statusText = 'EN LISTA DE ESPERA';
                            statusIcon = Icons.hourglass_top_rounded;
                          } else if (estado == 'cancelada' || estado == 'rechazado') {
                            statusColor = AppTheme.danger;
                            statusBg = const Color(0xFFFEE2E2);
                            statusText = 'CANCELADA';
                            statusIcon = Icons.cancel_outlined;
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.border, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lugar,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(statusIcon, color: statusColor, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              statusText,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                color: statusColor,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '$usuario ($email)',
                                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.electricBlue),
                                        const SizedBox(width: 6),
                                        Text(
                                          fecha,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          franja,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (estado != 'cancelada' && estado != 'rechazado') ...[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _cancelarReservaAdmin(reservaId),
                                        icon: const Icon(Icons.cancel_outlined, size: 15, color: AppTheme.danger),
                                        label: const Text(
                                          'Cancelar Reserva',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.danger,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, Color color) {
    final bool isSelected = _filtroEstado == label;
    return GestureDetector(
      onTap: () => setState(() => _filtroEstado = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.surfaceSubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
