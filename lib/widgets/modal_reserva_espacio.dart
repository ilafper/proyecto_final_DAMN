import 'package:flutter/material.dart';
import '../services/bbdd_service.dart';
import '../theme/app_theme.dart';

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

  String _normalizarFecha(dynamic fechaRaw) {
    if (fechaRaw == null) return '';
    final str = fechaRaw.toString().trim();
    if (str.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        final local = dt.toLocal();
        return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return str.split('T').first.trim();
  }

  bool _coincideFecha(dynamic fechaRaw, String fechaEsperada) {
    if (fechaRaw == null) return false;
    final fEsperada = fechaEsperada.trim();
    final fNorm = _normalizarFecha(fechaRaw);
    if (fNorm == fEsperada) return true;
    final fDirecta = fechaRaw.toString().split('T').first.trim();
    return fDirecta == fEsperada;
  }

  bool _coincideUsuario(dynamic rUserId, dynamic actualUserId) {
    if (rUserId == null || actualUserId == null) return false;
    final rStr = rUserId.toString().trim();
    final aStr = actualUserId.toString().trim();
    return rStr.isNotEmpty && aStr.isNotEmpty && rStr == aStr;
  }

  String _obtenerEstadoDia(DateTime fecha) {
    final fechaStr = _formatearFecha(fecha);

    final reservasDelDia = _reservasEspacio.where((r) {
      final coincide = _coincideFecha(r['fecha'] ?? r['fecha_inicio'], fechaStr);
      final rEstado = (r['estado'] ?? '').toString().toLowerCase().trim();
      return coincide && rEstado != 'cancelada';
    }).toList();

    if (reservasDelDia.isEmpty) return 'libre';

    // ¿El usuario actual tiene alguna reserva en este día?
    final tienePropia = reservasDelDia.any((r) {
      final rUser = r['usuario_id'] ?? r['id_usuario'];
      return _coincideUsuario(rUser, widget.usuarioId);
    });

    if (tienePropia) return 'propia';
    if (reservasDelDia.length >= _franjas.length) return 'ocupado';

    final tieneEspera = reservasDelDia.any(
      (r) => (r['estado'] ?? '').toString().toLowerCase().trim() == 'en_espera',
    );
    if (tieneEspera) return 'en_espera';

    return 'libre';
  }

  /// Obtiene la reserva activa que pertenece al usuario actual para esa franja horaria (si existe)
  Map<String, dynamic>? _obtenerReservaPropiaEnFranja(String franja) {
    if (_diaSeleccionado == null || widget.usuarioId == null) return null;
    final fechaStr = _formatearFecha(_diaSeleccionado!).trim();

    for (final r in _reservasEspacio) {
      final coincide = _coincideFecha(r['fecha'] ?? r['fecha_inicio'], fechaStr);
      final rFranja = (r['franja_horaria'] ?? '').toString().trim();
      final rEstado = (r['estado'] ?? '').toString().toLowerCase().trim();
      final rUser = r['usuario_id'] ?? r['id_usuario'];

      if (coincide &&
          rFranja == franja.trim() &&
          _coincideUsuario(rUser, widget.usuarioId) &&
          rEstado != 'cancelada') {
        return r;
      }
    }
    return null;
  }

  /// Obtiene una reserva confirmada en esa franja horaria (de cualquier usuario)
  Map<String, dynamic>? _obtenerReservaConfirmadaEnFranja(String franja) {
    if (_diaSeleccionado == null) return null;
    final fechaStr = _formatearFecha(_diaSeleccionado!).trim();

    for (final r in _reservasEspacio) {
      final coincide = _coincideFecha(r['fecha'] ?? r['fecha_inicio'], fechaStr);
      final rFranja = (r['franja_horaria'] ?? '').toString().trim();
      final rEstado = (r['estado'] ?? '').toString().toLowerCase().trim();

      if (coincide &&
          rFranja == franja.trim() &&
          rEstado == 'confirmada') {
        return r;
      }
    }
    return null;
  }

  /// Clasifica el estado de la franja horaria para el usuario actual:
  /// - 'propia_confirmada': El usuario ya tiene esta pista reservada y confirmada.
  /// - 'propia_en_espera': El usuario ya está en lista de espera para esta franja.
  /// - 'ocupada_otro': Pista confirmada por otro socio (se puede unir a lista de espera).
  /// - 'disponible': Franja libre para confirmación directa.
  String _getEstadoFranja(String franja) {
    final propia = _obtenerReservaPropiaEnFranja(franja);
    if (propia != null) {
      final estado = (propia['estado'] ?? '').toString().toLowerCase().trim();
      if (estado == 'confirmada') return 'propia_confirmada';
      if (estado == 'en_espera') return 'propia_en_espera';
    }

    final confirmada = _obtenerReservaConfirmadaEnFranja(franja);
    if (confirmada != null) {
      return 'ocupada_otro';
    }

    return 'disponible';
  }

  DateTime? _calcularInicioReserva() {
    if (_diaSeleccionado == null) return null;
    try {
      final franja = _franjas[_franjaIndex];
      final horaInicio = franja.split('-').first.trim();
      final partes = horaInicio.split(':');
      final hora = int.parse(partes[0]);
      final minuto = int.parse(partes[1]);
      return DateTime(
        _diaSeleccionado!.year,
        _diaSeleccionado!.month,
        _diaSeleccionado!.day,
        hora,
        minuto,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _cancelarReservaPropia(dynamic reservaId) async {
    final inicio = _calcularInicioReserva();
    final now = DateTime.now();
    final bool conMargen = inicio != null
        ? inicio.difference(now).inMinutes >= (12 * 60)
        : true;
    final int horasRestantes = inicio != null
        ? inicio.difference(now).inHours
        : 99;

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              conMargen
                  ? Icons.info_outline_rounded
                  : Icons.warning_amber_rounded,
              color: conMargen ? AppTheme.accent : AppTheme.warning,
            ),
            const SizedBox(width: 8),
            const Text('¿Cancelar reserva?'),
          ],
        ),
        content: Text(
          conMargen
              ? 'Faltan más de 12 horas ($horasRestantes h) para el inicio de tu turno.\n\n'
                  '✓ Se liberará la pista para otros socios.\n'
                  '✓ Se te reembolsará el 100% del importe abonado.'
              : '⚠️ ¡Aviso de cancelación tardía! Faltan menos de 12 horas para el inicio.\n\n'
                  '✓ La pista quedará liberada para la Lista de Espera o nuevos socios.\n'
                  '✗ NO se emitirá reembolso económico según la política de 12h del club.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: conMargen ? AppTheme.textPrimary : const Color(0xFF92400E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: conMargen ? AppTheme.accent : AppTheme.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(conMargen ? 'Confirmar y Reembolsar' : 'Cancelar sin reembolso'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _guardandoReserva = true);
    final resp = await _authService.cancelarReserva(reservaId);
    setState(() => _guardandoReserva = false);

    if (!mounted) return;

    if (resp['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            conMargen
                ? '✓ Reserva cancelada. Pista liberada y 100% reembolsado.'
                : 'Pista liberada para otros socios. Sin derecho a reembolso (<12h).',
          ),
          backgroundColor: conMargen ? const Color(0xFF059669) : AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      widget.onReservaConfirmada?.call();
      await _cargarReservasReales();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp['mensaje'] ?? 'No se pudo cancelar la reserva'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
    final String estadoFranja = _getEstadoFranja(franjaSeleccionada);

    if (estadoFranja == 'propia_confirmada') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya tienes esta pista reservada a tu nombre.'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (estadoFranja == 'propia_en_espera') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya te encuentras registrado en la lista de espera.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (eventoId == null || usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se ha detectado el usuario o la pista'),
        ),
      );
      return;
    }

    setState(() => _guardandoReserva = true);

    final bool vaAEspera = estadoFranja == 'ocupada_otro';
    final String estadoDeseado = vaAEspera ? 'en_espera' : 'confirmada';

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

      final String mensajeExito = vaAEspera
          ? '⏳ ¡Te has unido a la Lista de Espera! Si la pista se libera, entrarás automáticamente.'
          : '⚡ ¡Reserva confirmada al instante! Tu pista está lista.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['mensaje'] ?? mensajeExito),
          backgroundColor: vaAEspera ? AppTheme.warning : const Color(0xFF059669),
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
    final String ubicacion = e['ubicacion'] ?? '';
    final dynamic capacidad = e['capacidad_maxima'] ?? '4';
    final dynamic rawPrecio = e['precio_por_dia'] ?? '0';
    final double precioNum = double.tryParse(rawPrecio.toString()) ?? 0.0;
    final String precio = precioNum % 1 == 0
        ? '${precioNum.toInt()}.00'
        : precioNum.toStringAsFixed(2);

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

          // Cabecera del espacio / pista
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(
                    Icons.sports_tennis_rounded,
                    color: AppTheme.accent,
                    size: 24,
                  ),
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
                          letterSpacing: -0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ubicacion.isNotEmpty) ...[
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
                            const SizedBox(width: 14),
                            _buildPuntoLeyenda(
                              AppTheme.warning,
                              'Lista de Espera',
                            ),
                            const SizedBox(width: 14),
                            _buildPuntoLeyenda(
                              const Color(0xFF059669),
                              'Tu Reserva',
                            ),
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
                                childAspectRatio: 2.4,
                              ),
                          itemBuilder: (context, index) {
                            final franja = _franjas[index];
                            final bool esSeleccionada = _franjaIndex == index;
                            final String estado = _getEstadoFranja(franja);

                            Color bgColor = Colors.white;
                            Color borderColor = AppTheme.border;
                            Color textColor = AppTheme.textPrimary;
                            Color iconColor = AppTheme.textSecondary;
                            IconData iconData = Icons.schedule_rounded;
                            String? tagTexto;
                            Color tagColor = AppTheme.textMuted;

                            if (estado == 'propia_confirmada') {
                              iconData = Icons.check_circle_rounded;
                              tagTexto = 'TU RESERVA';
                              tagColor = const Color(0xFF059669);

                              if (esSeleccionada) {
                                bgColor = const Color(0xFFECFDF5);
                                borderColor = const Color(0xFF059669);
                                textColor = const Color(0xFF065F46);
                                iconColor = const Color(0xFF059669);
                              } else {
                                bgColor = const Color(0xFFF0FDF4);
                                borderColor = const Color(0xFFA7F3D0);
                                textColor = const Color(0xFF065F46);
                                iconColor = const Color(0xFF10B981);
                              }
                            } else if (estado == 'propia_en_espera') {
                              iconData = Icons.hourglass_top_rounded;
                              tagTexto = 'EN ESPERA (TÚ)';
                              tagColor = const Color(0xFFD97706);

                              if (esSeleccionada) {
                                bgColor = const Color(0xFFFEF3C7);
                                borderColor = AppTheme.warning;
                                textColor = const Color(0xFF92400E);
                                iconColor = AppTheme.warning;
                              } else {
                                bgColor = const Color(0xFFFFFBEB);
                                borderColor = const Color(0xFFFDE68A);
                                textColor = const Color(0xFF92400E);
                                iconColor = const Color(0xFFD97706);
                              }
                            } else if (estado == 'ocupada_otro') {
                              iconData = Icons.hourglass_top_rounded;
                              tagTexto = 'LISTA DE ESPERA';
                              tagColor = AppTheme.warning;

                              if (esSeleccionada) {
                                bgColor = const Color(0xFFFEF3C7);
                                borderColor = AppTheme.warning;
                                textColor = const Color(0xFF92400E);
                                iconColor = AppTheme.warning;
                                tagColor = const Color(0xFF92400E);
                              } else {
                                bgColor = const Color(0xFFF8FAFC);
                                borderColor = const Color(0xFFE2E8F0);
                                textColor = AppTheme.textMuted;
                                iconColor = AppTheme.textMuted;
                              }
                            } else {
                              // 'disponible'
                              iconData = Icons.schedule_rounded;
                              tagTexto = null;

                              if (esSeleccionada) {
                                bgColor = AppTheme.accent;
                                borderColor = AppTheme.accent;
                                textColor = Colors.white;
                                iconColor = Colors.white;
                              } else {
                                bgColor = Colors.white;
                                borderColor = AppTheme.border;
                                textColor = AppTheme.textPrimary;
                                iconColor = AppTheme.textSecondary;
                              }
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
                                            color: (estado == 'propia_confirmada'
                                                    ? const Color(0xFF059669)
                                                    : estado == 'ocupada_otro' ||
                                                            estado ==
                                                                'propia_en_espera'
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
                                      iconData,
                                      size: 16,
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
                                            decoration: (estado ==
                                                        'ocupada_otro' &&
                                                    !esSeleccionada)
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        if (tagTexto != null)
                                          Text(
                                            tagTexto,
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                              color: tagColor,
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
                  final String franjaSeleccionada = _franjas[_franjaIndex];
                  final String estadoActual =
                      _getEstadoFranja(franjaSeleccionada);
                  final Map<String, dynamic>? reservaPropia =
                      _obtenerReservaPropiaEnFranja(franjaSeleccionada);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Banner informativo según el estado
                      if (estadoActual == 'propia_confirmada')
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF059669),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '¡Ya tienes esta pista reservada a tu nombre! Si no vas a asistir, puedes cancelarla para que pase a otro socio.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF065F46),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (estadoActual == 'propia_en_espera')
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.hourglass_top_rounded,
                                color: Color(0xFFD97706),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Estás registrado en la Lista de Espera de este horario. Si el titular actual cancela, entrarás automáticamente.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (estadoActual == 'ocupada_otro')
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
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

                      // Botones de acción inferiores
                      if (estadoActual == 'propia_confirmada')
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF059669),
                                      size: 19,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Pista reservada por ti',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF065F46),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _guardandoReserva || reservaPropia == null
                                        ? null
                                        : () => _cancelarReservaPropia(
                                            reservaPropia['id'],
                                          ),
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 17,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.danger,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (estadoActual == 'propia_en_espera')
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.hourglass_top_rounded,
                                      color: Color(0xFFD97706),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'En Lista de Espera',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed:
                                    _guardandoReserva || reservaPropia == null
                                        ? null
                                        : () => _cancelarReservaPropia(
                                            reservaPropia['id'],
                                          ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppTheme.danger,
                                    width: 1.3,
                                  ),
                                  foregroundColor: AppTheme.danger,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Salir de cola',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  estadoActual == 'ocupada_otro'
                                      ? 'Depósito cola'
                                      : 'Total sesión',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$precio €',
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
                                    backgroundColor:
                                        estadoActual == 'ocupada_otro'
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
                                              estadoActual == 'ocupada_otro'
                                                  ? Icons.hourglass_top_rounded
                                                  : Icons.bolt_rounded,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              estadoActual == 'ocupada_otro'
                                                  ? 'Unirse a Lista de Espera'
                                                  : 'Reservar Pista',
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
            if (estado == 'propia') {
              dotColor = const Color(0xFF059669);
            } else if (estado == 'en_espera' || estado == 'pendiente') {
              dotColor = AppTheme.warning;
            } else if (estado == 'ocupado') {
              dotColor = AppTheme.danger;
            }

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
                              ? (estado == 'propia'
                                  ? const Color(0xFF34D399)
                                  : AppTheme.accentLight)
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
