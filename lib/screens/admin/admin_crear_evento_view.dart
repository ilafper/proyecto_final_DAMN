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
    final capacidadCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
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
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nuevo Espacio / Lugar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nombreCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre del espacio *',
                        hintText: 'Ej. Cancha de Pádel o Sala Magna',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.meeting_room_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: ubicacionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ubicación / Dirección',
                        hintText: 'Ej. Calle Mayor 12, Panta 2',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Ej. Dispone de proyector, luz nocturna...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: capacidadCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Capacidad Máx *',
                              hintText: 'Ej. 20',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.people_outline_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: precioCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Precio por día (€) *',
                              hintText: 'Ej. 25.0',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.euro_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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
                                );

                                setModalState(() => guardando = false);

                                if (res['success'] == true) {
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(res['mensaje'] ?? 'Espacio creado con éxito')),
                                    );
                                    _cargarEspacios();
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(res['mensaje'] ?? 'Error al crear')),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: guardando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Guardar evento',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),

                            
                      ),
                    ),
                     const SizedBox(height: 50),
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
      onRefresh: _cargarEspacios,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón principal para abrir el modal
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _mostrarModalCrearEspacio(context),
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text(
                  'Añadir Nuevo Espacio / Sitio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Espacios en tu Base de Datos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                if (!_cargando)
                  Text(
                    '${_espacios.length} registrados',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_espacios.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'No hay espacios registrados aún',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Usa el botón de arriba para registrar tu primer lugar.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                  final nombre = e['nombre'] ?? 'Sin nombre';
                  final ubicacion = e['ubicacion'] ?? 'Sin dirección';
                  final capacidad = e['capacidad_maxima'] ?? '-';
                  final precio = e['precio_por_dia'] ?? '0';

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icono centrado horizontal y verticalmente
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              color: AppTheme.accent,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Textos descriptivos
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  ubicacion,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.people_outline_rounded, size: 13, color: AppTheme.textMuted),
                                    const SizedBox(width: 4),
                                    Text('$capacidad pers', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.euro_rounded, size: 13, color: AppTheme.textMuted),
                                    const SizedBox(width: 2),
                                    Text('$precio€/día', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accent)),
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
