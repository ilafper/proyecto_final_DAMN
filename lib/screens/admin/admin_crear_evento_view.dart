import 'package:flutter/material.dart';
import '../../services/bbdd_service.dart';
import '../../theme/app_theme.dart';

class AdminCrearEventoView extends StatefulWidget {
  const AdminCrearEventoView({super.key});

  @override
  State<AdminCrearEventoView> createState() => _AdminCrearEventoViewState();
}

class _AdminCrearEventoViewState extends State<AdminCrearEventoView> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _espacios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEspacios();
  }

  Future<void> _cargarEspacios() async {
    setState(() => _cargando = true);
    final lista = await _authService.getEspacios();
    if (mounted) {
      setState(() {
        _espacios = lista;
        _cargando = false;
      });
    }
  }

  void _mostrarModalCrearEspacio(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ubicacionCtrl = TextEditingController();
    final capacidadCtrl = TextEditingController(text: '4');
    final precioCtrl = TextEditingController(text: '20.0');
    String categoriaSeleccionada = 'padel';
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nuevo Espacio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Selector de Categoría (Pádel vs Locales)
                    const Text(
                      'Categoría del Espacio *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                categoriaSeleccionada = 'padel';
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: categoriaSeleccionada == 'padel'
                                    ? AppTheme.accent.withValues(alpha: 0.12)
                                    : AppTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: categoriaSeleccionada == 'padel'
                                      ? AppTheme.accent
                                      : AppTheme.border,
                                  width: categoriaSeleccionada == 'padel' ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.sports_tennis_rounded,
                                    size: 18,
                                    color: categoriaSeleccionada == 'padel'
                                        ? AppTheme.accent
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pádel & Canchas',
                                    style: TextStyle(
                                      fontWeight: categoriaSeleccionada == 'padel'
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 13,
                                      color: categoriaSeleccionada == 'padel'
                                          ? AppTheme.accent
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                categoriaSeleccionada = 'locales';
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: categoriaSeleccionada == 'locales'
                                    ? AppTheme.partyPurple.withValues(alpha: 0.12)
                                    : AppTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: categoriaSeleccionada == 'locales'
                                      ? AppTheme.partyPurple
                                      : AppTheme.border,
                                  width: categoriaSeleccionada == 'locales' ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.celebration_rounded,
                                    size: 18,
                                    color: categoriaSeleccionada == 'locales'
                                        ? AppTheme.partyPurple
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Locales & Eventos',
                                    style: TextStyle(
                                      fontWeight: categoriaSeleccionada == 'locales'
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 13,
                                      color: categoriaSeleccionada == 'locales'
                                          ? AppTheme.partyPurple
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        hintText: 'Ej. Pista 1, Local Principal, etc.',
                        prefixIcon: Icon(Icons.sports_tennis_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ubicacionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación *',
                        hintText: 'Ej. Zona 1, Planta Baja',
                        prefixIcon: Icon(Icons.place_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Detalles o notas adicionales...',
                        prefixIcon: Icon(Icons.description_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: capacidadCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Capacidad máx *',
                              hintText: '4',
                              prefixIcon: Icon(Icons.people_outline_rounded, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: precioCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Precio sesión (€) *',
                              hintText: '20.0',
                              prefixIcon: Icon(Icons.euro_rounded, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: guardando
                            ? null
                            : () async {
                                final nombre = nombreCtrl.text.trim();
                                final ubicacion = ubicacionCtrl.text.trim();
                                final desc = descCtrl.text.trim();
                                final cap = int.tryParse(capacidadCtrl.text.trim());
                                final precio = double.tryParse(precioCtrl.text.trim());

                                if (nombre.isEmpty || cap == null || cap <= 0 || precio == null || precio < 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Por favor completa Nombre, Capacidad (>0) y Precio válidos.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => guardando = true);

                                final res = await _authService.crearEspacio(
                                  nombre: nombre,
                                  descripcion: desc,
                                  ubicacion: ubicacion,
                                  capacidadMaxima: cap,
                                  precioPorDia: precio,
                                  categoria: categoriaSeleccionada,
                                );

                                setModalState(() => guardando = false);

                                if (res['success'] == true) {
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res['mensaje'] ?? 'Pista registrada con éxito'),
                                        backgroundColor: AppTheme.accent,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                    _cargarEspacios();
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res['mensaje'] ?? 'Error al registrar la pista'),
                                        backgroundColor: AppTheme.danger,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: guardando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_circle_outline_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Publicar Espacio',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _cargarEspacios,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón principal
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _mostrarModalCrearEspacio(context),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  'Añadir Nuevo Espacio',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Espacios Registrados',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (!_cargando)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_espacios.length} pistas',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              )
            else if (_espacios.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border, width: 1.2),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.sports_tennis_rounded, size: 48, color: AppTheme.textMuted),
                    SizedBox(height: 14),
                    Text(
                      'No hay pistas registradas aún',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Usa el botón superior para dar de alta tu primera pista.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _espacios.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final e = _espacios[index];
                  final nombre = e['nombre'] ?? 'Espacio';
                  final ubicacion = (e['ubicacion'] ?? '').toString();
                  final capacidad = e['capacidad_maxima'] ?? '4';
                  final precio = e['precio_por_dia'] ?? '0';
                  final cat = (e['categoria'] ?? 'padel').toString().toLowerCase();
                  final bool esLocal = cat == 'locales' || cat == 'local' || cat == 'evento' || cat == 'eventos';
                  final IconData itemIcon = esLocal ? Icons.celebration_rounded : Icons.sports_tennis_rounded;
                  final Color itemColor = esLocal ? AppTheme.partyPurple : AppTheme.accent;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border, width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: itemColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              itemIcon,
                              color: itemColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: itemColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        esLocal ? 'LOCAL' : 'PÁDEL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: itemColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ubicacion,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.people_outline_rounded, size: 12, color: AppTheme.textMuted),
                                    const SizedBox(width: 3),
                                    Text('Máx $capacidad', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                    const SizedBox(width: 10),
                                    Text('$precio€ / sesión', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: itemColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
