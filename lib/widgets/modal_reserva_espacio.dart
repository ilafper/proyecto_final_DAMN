import 'package:flutter/material.dart';
import '../services/bbdd_service.dart';
import '../theme/app_theme.dart';
import '../utils/venue_visual_helper.dart';

/// Modal interactivo estilo Playtomic para consultar disponibilidad y reservar pistas deportivas.
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

  String _formatearFecha(DateTime fecha) {
    final y = fecha.year.toString();
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _obtenerEstadoDia(DateTime fecha) {
    final fechaStr = _formatearFecha(fecha);

    final reservasDelDia = _reservasEspacio.where((r) {
      final rFecha = (r['fecha'] ?? r['fecha_inicio'] ?? '')
          .toString()
          .split('T')
          .first;
      return rFecha == fechaStr;
    }).toList();

    if (reservasDelDia.isEmpty) return 'libre';
    if (reservasDelDia.length >= _franjas.length) return 'ocupado';

    final tienePendiente = reservasDelDia.any(
      (r) => (r['estado'] ?? '').toString().toLowerCase() == 'pendiente',
    );
    if (tienePendiente) return 'pendiente';

    return 'libre';
  }

  bool _franjaEstaOcupada(String franja) {
    if (_diaSeleccionado == null) return false;
    final fechaStr = _formatearFecha(_diaSeleccionado!);

    return _reservasEspacio.any((r) {
      final rFecha = (r['fecha'] ?? r['fecha_inicio'] ?? '')
          .toString()
          .split('T')
          .first;
      final rFranja = (r['franja_horaria'] ?? '').toString();
      final rEstado = (r['estado'] ?? '').toString().toLowerCase();

      return rFecha == fechaStr && rFranja == franja && rEstado != 'cancelada';
    });
  }

  Future<void> _confirmarReserva() async {
    if (_diaSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una fecha en el calendario'),
        ),
      );
      return;
    }

    final eventoId = widget.espacio['id'];
    final usuarioId = widget.usuarioId;
    final fechaSeleccionada = _formatearFecha(_diaSeleccionado!);
    final franjaSeleccionada = _franjas[_franjaIndex];
    final bool estaOcupada = _franjaEstaOcupada(franjaSeleccionada);

    if (eventoId == null || usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se ha detectado el usuario o la pista'),
        ),
      );
      return;
    }

    setState(() => _guardandoReserva = true);

    final String estadoDeseado = estaOcupada ? 'en_espera' : 'confirmada';

    final respuesta = await _authService.crearReserva(
      eventoId: eventoId,
      usuarioId: usuarioId,
      fecha: fechaSeleccionada,
      franjaHoraria: franjaSeleccionada,
      estado: estadoDeseado,
    );

    setState(() => _guardandoReserva = false);

    if (!mounted) return;

    if (respuesta['success'] == true) {
      Navigator.pop(context);

      final String mensajeExito = estaOcupada
          ? '⏳ ¡Te has unido a la Lista de Espera! Si la pista se libera, entrarás automáticamente.'
          : '⚡ ¡Reserva confirmada al instante! Tu pista está lista.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['mensaje'] ?? mensajeExito),
          backgroundColor: estaOcupada ? AppTheme.warning : AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      widget.onReservaConfirmada?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            respuesta['mensaje'] ?? 'No se pudo procesar la solicitud',
          ),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.espacio;
    final String nombre = e['nombre'] ?? 'Pista Deportiva';
    final String ubicacion = e['ubicacion'] ?? 'Club Principal';
    final dynamic capacidad = e['capacidad_maxima'] ?? '4';
    final dynamic precio = e['precio_por_dia'] ?? '15';
    final typeInfo = VenueVisualHelper.getTypeInfo(e);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        children: [
          // Tirador superior
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Cabecera del espacio / pista con badge dinámico
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeInfo.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: typeInfo.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(typeInfo.icon, color: typeInfo.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nombre,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeInfo.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeInfo.tag,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: typeInfo.color,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ubicacion,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    '$precio€ / sesión',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // Calendario y Horarios
          Expanded(
            child: _cargandoReservas
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderMes(),
                        const SizedBox(height: 12),
                        _buildCalendario(),
                        const SizedBox(height: 16),

                        // Leyenda
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPuntoLeyenda(AppTheme.accent, 'Disponible'),
                            const SizedBox(width: 18),
                            _buildPuntoLeyenda(
                              AppTheme.warning,
                              'Lista de Espera',
                            ),
                            const SizedBox(width: 18),
                            _buildPuntoLeyenda(AppTheme.danger, 'Ocupada'),
                          ],
                        ),

                        const SizedBox(height: 22),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 18),

                        // Selector de Franjas Horarias
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Horarios Disponibles',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Aforo: $capacidad pers',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _franjas.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.7,
                              ),
                          itemBuilder: (context, index) {
                            final franja = _franjas[index];
                            final bool esSeleccionada = _franjaIndex == index;
                            final bool ocupada = _franjaEstaOcupada(franja);

                            Color bgColor = Colors.white;
                            Color borderColor = AppTheme.border;
                            Color textColor = AppTheme.textPrimary;
                            Color iconColor = AppTheme.textSecondary;

                            if (esSeleccionada) {
                              if (ocupada) {
                                bgColor = const Color(0xFFFEF3C7);
                                borderColor = AppTheme.warning;
                                textColor = const Color(0xFF92400E);
                                iconColor = AppTheme.warning;
                              } else {
                                bgColor = AppTheme.accent;
                                borderColor = AppTheme.accent;
                                textColor = Colors.white;
                                iconColor = Colors.white;
                              }
                            } else if (ocupada) {
                              bgColor = const Color(0xFFF8FAFC);
                              borderColor = const Color(0xFFE2E8F0);
                              textColor = AppTheme.textMuted;
                              iconColor = AppTheme.textMuted;
                            }

                            return InkWell(
                              onTap: () => setState(() => _franjaIndex = index),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: borderColor,
                                    width: esSeleccionada ? 1.8 : 1.2,
                                  ),
                                  boxShadow: esSeleccionada
                                      ? [
                                          BoxShadow(
                                            color:
                                                (ocupada
                                                        ? AppTheme.warning
                                                        : AppTheme.accent)
                                                    .withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      ocupada
                                          ? Icons.hourglass_top_rounded
                                          : Icons.schedule_rounded,
                                      size: 15,
                                      color: iconColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          franja,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: esSeleccionada
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: textColor,
                                            decoration:
                                                (ocupada && !esSeleccionada)
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        if (ocupada)
                                          Text(
                                            'LISTA DE ESPERA',
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                              color: esSeleccionada
                                                  ? const Color(0xFF92400E)
                                                  : AppTheme.warning,
                                              letterSpacing: 0.3,
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
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
          ),

          // Barra inferior de confirmación
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Builder(
                builder: (context) {
                  final bool franjaActualOcupada = _franjaEstaOcupada(
                    _franjas[_franjaIndex],
                  );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (franjaActualOcupada)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFFD97706),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pista ocupada en este horario. Al unirte quedarás en Lista de Espera y entrarás automáticamente si el titular cancela.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                franjaActualOcupada
                                    ? 'Depósito cola'
                                    : 'Total sesión',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$precio,00 €',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _guardandoReserva
                                    ? null
                                    : _confirmarReserva,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: franjaActualOcupada
                                      ? AppTheme.warning
                                      : AppTheme.accent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _guardandoReserva
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            franjaActualOcupada
                                                ? Icons.hourglass_top_rounded
                                                : Icons.bolt_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            franjaActualOcupada
                                                ? 'Unirse a Lista de Espera'
                                                : 'Reservar',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMes() {
    final List<String> meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final String mesTexto = '${meses[_mesActual.month - 1]} ${_mesActual.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          mesTexto,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _mesActual = DateTime(
                    _mesActual.year,
                    _mesActual.month - 1,
                    1,
                  );
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _mesActual = DateTime(
                    _mesActual.year,
                    _mesActual.month + 1,
                    1,
                  );
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendario() {
    final diasEnMes = DateTime(_mesActual.year, _mesActual.month + 1, 0).day;
    final primerDiaSemana = DateTime(
      _mesActual.year,
      _mesActual.month,
      1,
    ).weekday;
    final List<String> diasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: diasSemana
              .map(
                (d) => SizedBox(
                  width: 34,
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              )
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
            final fechaDia = DateTime(
              _mesActual.year,
              _mesActual.month,
              diaNum,
            );

            final bool esSeleccionado =
                _diaSeleccionado != null &&
                _diaSeleccionado!.year == fechaDia.year &&
                _diaSeleccionado!.month == fechaDia.month &&
                _diaSeleccionado!.day == fechaDia.day;

            final now = DateTime.now();
            final hoy = DateTime(now.year, now.month, now.day);
            final bool esPasado = fechaDia.isBefore(hoy);

            final estado = _obtenerEstadoDia(fechaDia);
            final bool estaOcupado = estado == 'ocupado';

            Color dotColor = AppTheme.accent;
            if (estado == 'en_espera' || estado == 'pendiente')
              dotColor = AppTheme.warning;
            if (estado == 'ocupado') dotColor = AppTheme.danger;

            return InkWell(
              onTap: esPasado
                  ? null
                  : () => setState(() => _diaSeleccionado = fechaDia),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: esSeleccionado
                      ? AppTheme.primary
                      : AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
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
                        fontWeight: esSeleccionado
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: esSeleccionado
                            ? Colors.white
                            : esPasado
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (!esPasado)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: esSeleccionado
                              ? AppTheme.accentLight
                              : dotColor,
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
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
