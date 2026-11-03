import 'package:flutter/material.dart';
import '../services/bbdd_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/modal_reserva_espacio.dart';
import 'auth_screen.dart';

class UserScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const UserScreen({super.key, required this.usuario});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  List<Map<String, dynamic>> _espacios = [];
  List<Map<String, dynamic>> _misReservas = [];
  bool _cargandoEspacios = true;
  bool _cargandoReservas = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    _cargarEspacios();
    _cargarMisReservas();
  }

  Future<void> _cargarEspacios() async {
    setState(() => _cargandoEspacios = true);
    final lista = await _authService.getEspacios();
    if (mounted) {
      setState(() {
        _espacios = lista;
        _cargandoEspacios = false;
      });
    }
  }

  Future<void> _cargarMisReservas() async {
    setState(() => _cargandoReservas = true);
    final userId = widget.usuario['id'];
    final lista = await _authService.getReservas(usuarioId: userId);
    if (mounted) {
      setState(() {
        _misReservas = lista;
        _cargandoReservas = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nombre = widget.usuario['nombre'] ?? widget.usuario['nombre_completo'] ?? 'Cliente';
    final String email = widget.usuario['email'] ?? '';
    final String rol = (widget.usuario['rol'] ?? 'cliente').toString().toLowerCase();

    final List<String> titulos = [
      'Explorar Espacios',
      'Mis Reservas',
      'Mi Perfil',
    ];

    final List<Widget> pages = [
      _buildExplorarTab(),
      _buildMisCitasTab(),
      _buildPerfilTab(nombre, email, rol),
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
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        rol: rol,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  // --- PESTAÑA 0: EXPLORAR LUGARES REALES DE LA BBDD ---
  Widget _buildExplorarTab() {
    return RefreshIndicator(
      onRefresh: _cargarEspacios,
      child: _cargandoEspacios
          ? const Center(child: CircularProgressIndicator())
          : _espacios.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.storefront_outlined, size: 56, color: AppTheme.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'No hay espacios disponibles',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'El administrador aún no ha publicado espacios para alquilar.',
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
                  itemCount: _espacios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final e = _espacios[index];
                    final nombre = e['nombre'] ?? 'Sin nombre';
                    final ubicacion = e['ubicacion'] ?? 'Sin ubicación';
                    final capacidad = e['capacidad_maxima'] ?? '-';
                    final precio = e['precio_por_dia'] ?? '0';
                    final desc = e['descripcion'] ?? '';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.meeting_room_rounded, color: AppTheme.accent, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        ubicacion,
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(desc, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.people_outline_rounded, size: 16, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text('Hasta $capacidad pers', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                const SizedBox(width: 16),
                                const Icon(Icons.euro_rounded, size: 16, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text('$precio€ / día', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) => ModalReservaEspacio(
                                      espacio: e,
                                      usuarioId: widget.usuario['id'],
                                      onReservaConfirmada: _cargarDatos,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                                label: const Text('Ver Calendario y Reservar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // --- PESTAÑA 1: MIS RESERVAS REALES ---
  Widget _buildMisCitasTab() {
    return RefreshIndicator(
      onRefresh: _cargarMisReservas,
      child: _cargandoReservas
          ? const Center(child: CircularProgressIndicator())
          : _misReservas.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.calendar_today_outlined, size: 56, color: AppTheme.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'No tienes reservas activas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Explora los espacios disponibles y agenda tu primer lugar.',
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
                  itemCount: _misReservas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = _misReservas[index];
                    final lugar = r['espacio_nombre'] ?? 'Espacio #${r['evento_id'] ?? r['espacio_id']}';
                    final fecha = (r['fecha'] ?? r['fecha_inicio'] ?? '').toString().split('T').first;
                    final franja = r['franja_horaria'] ?? '';
                    final estado = (r['estado'] ?? 'pendiente').toString();
                    Color badgeColor = Colors.orange;
                    Color badgeBg = Colors.orange.shade50;

                    if (estado.toLowerCase() == 'reservado' || estado.toLowerCase() == 'confirmada') {
                      badgeColor = Colors.green.shade800;
                      badgeBg = Colors.green.shade50;
                    } else if (estado.toLowerCase() == 'rechazado' || estado.toLowerCase() == 'cancelada') {
                      badgeColor = Colors.red.shade800;
                      badgeBg = Colors.red.shade50;
                    }

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lugar,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    estado.toUpperCase(),
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(fecha, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                if (franja.isNotEmpty) ...[
                                  const SizedBox(width: 14),
                                  const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(franja, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                ],
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

  // --- PESTAÑA 2: PERFIL DE USUARIO ---
  Widget _buildPerfilTab(String nombre, String email, String rol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 34,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, $nombre!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ROL: ${rol.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Cuenta y Preferencias',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_outlined, color: Colors.blue),
              ),
              title: const Text('Datos Personales', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(email, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
