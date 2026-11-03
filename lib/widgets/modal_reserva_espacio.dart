import 'package:flutter/material.dart';
import '../services/bbdd_service.dart';
import '../theme/app_theme.dart';

/// Modal sobrio, interactivo y conectado con el backend para consultar
/// disponibilidad real y confirmar reservas en la BBDD.
class ModalReservaEspacio extends StatefulWidget {
  final Map<String, dynamic> espacio;
  final dynamic usuarioId;
  final VoidCallback? onReservaConfirmada;

  const ModalReservaEspacio({
    super.key,
    required this.espacio,
    this.usuarioId,
    this.onReservaConfirmada,
  });

  @override
  State<ModalReservaEspacio> createState() => _ModalReservaEspacioState();
}

class _ModalReservaEspacioState extends State<ModalReservaEspacio> {
  final AuthService _authService = AuthService();

  late DateTime _mesActual;
  DateTime? _diaSeleccionado;
  int _franjaIndex = 0;

  List<Map<String, dynamic>> _reservasEspacio = [];
  bool _cargandoReservas = true;
  bool _guardandoReserva = false;

  // Franjas horarias fijas
  final List<String> _franjas = [
    '09:00 - 10:30',
    '10:30 - 12:00',
    '12:00 - 13:30',
    '16:00 - 17:30',
    '17:30 - 19:00',
    '19:00 - 20:30',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesActual = DateTime(now.year, now.month, 1);
    _diaSeleccionado = DateTime(now.year, now.month, now.day);
    _cargarReservasReales();
  }

  // Cargar reservas existentes para comprobar ocupación
  Future<void> _cargarReservasReales() async {
    final eventoId = widget.espacio['id'];
    if (eventoId != null) {
      final reservas = await _authService.getReservas(eventoId: eventoId);
      if (mounted) {
        setState(() {
          _reservasEspacio = reservas;
          _cargandoReservas = false;
        });
      }
    } else {
      if (mounted) setState(() => _cargandoReservas = false);
    }
  }

  // Formatear DateTime a YYYY-MM-DD
  String _formatearFecha(DateTime fecha) {
    final y = fecha.year.toString();
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Comprobar estado de un día según las reservas de la BBDD
  String _obtenerEstadoDia(DateTime fecha) {
    final fechaStr = _formatearFecha(fecha);

    final reservasDelDia = _reservasEspacio.where((r) {
      final rFecha = (r['fecha'] ?? r['fecha_inicio'] ?? '').toString().split('T').first;
      return rFecha == fechaStr;
    }).toList();

    if (reservasDelDia.isEmpty) {
      return 'libre'; // Verde
    }

    // Si todas las franjas están ocupadas ese día
    if (reservasDelDia.length >= _franjas.length) {
      return 'ocupado'; // Rojo
    }

    final tienePendiente = reservasDelDia.any((r) => (r['estado'] ?? '').toString().toLowerCase() == 'pendiente');
    if (tienePendiente) {
      return 'pendiente'; // Amarillo
    }

    return 'libre';
  }

  // Comprobar si una franja horaria en concreto ya está reservada en el día seleccionado
  bool _franjaEstaOcupada(String franja) {
    if (_diaSeleccionado == null) return false;
    final fechaStr = _formatearFecha(_diaSeleccionado!);

    return _reservasEspacio.any((r) {
      final rFecha = (r['fecha'] ?? r['fecha_inicio'] ?? '').toString().split('T').first;
      final rFranja = (r['franja_horaria'] ?? '').toString();
      final rEstado = (r['estado'] ?? '').toString().toLowerCase();

      return rFecha == fechaStr && rFranja == franja && rEstado != 'cancelada';
    });
  }

  // ENVIAR RESERVA REAL A LA BASE DE DATOS (POST /api/reservas)
  Future<void> _confirmarReserva() async {
    if (_diaSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una fecha en el calendario')),
      );
      return;
    }

    final eventoId = widget.espacio['id'];
    final usuarioId = widget.usuarioId;
    final fechaSeleccionada = _formatearFecha(_diaSeleccionado!);
    final franjaSeleccionada = _franjas[_franjaIndex];

    if (eventoId == null || usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se ha detectado el ID del usuario o del espacio')),
      );
      return;
    }

    setState(() => _guardandoReserva = true);

    final respuesta = await _authService.crearReserva(
      eventoId: eventoId,
      usuarioId: usuarioId,
      fecha: fechaSeleccionada,
      franjaHoraria: franjaSeleccionada,
      estado: 'pendiente', // Se crea en estado PENDIENTE a la espera de aprobación del admin
    );

    setState(() => _guardandoReserva = false);

    if (!mounted) return;

    if (respuesta['success'] == true) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['mensaje'] ?? '¡Reserva confirmada con éxito!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onReservaConfirmada?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['mensaje'] ?? 'No se pudo crear la reserva'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.espacio;
    final String nombre = e['nombre'] ?? 'Espacio';
    final String ubicacion = e['ubicacion'] ?? 'Ubicación no especificada';
    final dynamic capacidad = e['capacidad_maxima'] ?? '-';
    final dynamic precio = e['precio_por_dia'] ?? '0';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        children: [
          // Tirador superior
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Cabecera elegante y sobria
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ubicacion,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    '$precio€ / día',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // Contenido
          Expanded(
            child: _cargandoReservas
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderMes(),
                        const SizedBox(height: 12),
                        _buildCalendario(),
                        const SizedBox(height: 16),

                        // Leyenda de estados
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPuntoLeyenda(const Color(0xFF10B981), 'Disponible'),
                            const SizedBox(width: 20),
                            _buildPuntoLeyenda(const Color(0xFFF59E0B), 'Pendiente'),
                            const SizedBox(width: 20),
                            _buildPuntoLeyenda(const Color(0xFFEF4444), 'Completo'),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 20),

                        // Franjas horarias
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Horarios Disponibles',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Aforo: $capacidad pers',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Grid simétrico de franjas
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _franjas.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.8,
                          ),
                          itemBuilder: (context, index) {
                            final franja = _franjas[index];
                            final bool esSeleccionada = _franjaIndex == index;
                            final bool ocupada = _franjaEstaOcupada(franja);

                            return InkWell(
                              onTap: ocupada
                                  ? null
                                  : () => setState(() => _franjaIndex = index),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: ocupada
                                      ? Colors.grey.shade100
                                      : (esSeleccionada ? AppTheme.primary : Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: ocupada
                                        ? Colors.grey.shade300
                                        : (esSeleccionada ? AppTheme.primary : AppTheme.border),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      ocupada ? Icons.block_rounded : Icons.access_time_rounded,
                                      size: 15,
                                      color: ocupada
                                          ? AppTheme.textMuted
                                          : (esSeleccionada ? Colors.white70 : AppTheme.textSecondary),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      franja,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: esSeleccionada ? FontWeight.w600 : FontWeight.w500,
                                        color: ocupada
                                            ? AppTheme.textMuted
                                            : (esSeleccionada ? Colors.white : AppTheme.textPrimary),
                                        decoration: ocupada ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),

          // Botón inferior para enviar la reserva a la BBDD
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _guardandoReserva ? null : _confirmarReserva,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _guardandoReserva
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Confirmar Reserva',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMes() {
    final List<String> meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final String mesTexto = '${meses[_mesActual.month - 1]} ${_mesActual.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          mesTexto,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _mesActual = DateTime(_mesActual.year, _mesActual.month - 1, 1);
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.chevron_left_rounded, size: 18, color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _mesActual = DateTime(_mesActual.year, _mesActual.month + 1, 1);
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendario() {
    final diasEnMes = DateTime(_mesActual.year, _mesActual.month + 1, 0).day;
    final primerDiaSemana = DateTime(_mesActual.year, _mesActual.month, 1).weekday;
    final List<String> diasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: diasSemana
              .map((d) => SizedBox(
                    width: 34,
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: (primerDiaSemana - 1) + diasEnMes,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            if (index < primerDiaSemana - 1) {
              return const SizedBox();
            }

            final diaNum = index - (primerDiaSemana - 1) + 1;
            final fechaDia = DateTime(_mesActual.year, _mesActual.month, diaNum);

            final bool esSeleccionado = _diaSeleccionado != null &&
                _diaSeleccionado!.year == fechaDia.year &&
                _diaSeleccionado!.month == fechaDia.month &&
                _diaSeleccionado!.day == fechaDia.day;

            final estado = _obtenerEstadoDia(fechaDia);
            final bool estaOcupado = estado == 'ocupado';

            Color dotColor = const Color(0xFF10B981);
            if (estado == 'pendiente') dotColor = const Color(0xFFF59E0B);
            if (estado == 'ocupado') dotColor = const Color(0xFFEF4444);

            return InkWell(
              onTap: estaOcupado
                  ? null
                  : () => setState(() => _diaSeleccionado = fechaDia),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: esSeleccionado ? AppTheme.primary : AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: esSeleccionado ? AppTheme.primary : AppTheme.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$diaNum',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: esSeleccionado ? FontWeight.bold : FontWeight.w500,
                        color: esSeleccionado
                            ? Colors.white
                            : estaOcupado
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: esSeleccionado ? Colors.white : dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPuntoLeyenda(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
