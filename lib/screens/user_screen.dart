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

  // Filtros de búsqueda estilo Playtomic
  String _busqueda = '';
  String _categoriaSeleccionada = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categorias = [
    {
      'nombre': 'Todos',
      'icon': Icons.explore_rounded,
      'color': AppTheme.primary,
    },
    {
      'nombre': 'Locales & Eventos',
      'icon': Icons.celebration_rounded,
      'color': AppTheme.partyPurple,
    },
    {
      'nombre': 'Pádel & Tenis',
      'icon': Icons.sports_tennis_rounded,
      'color': AppTheme.accent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Map<String, dynamic> _obtenerInfoVisual(Map<String, dynamic> espacio) {
    final cat = (espacio['categoria'] ?? '').toString().toLowerCase().trim();
    final nombre = (espacio['nombre'] ?? '').toString().toLowerCase();
    final desc = (espacio['descripcion'] ?? '').toString().toLowerCase();
    final combined = '$nombre $desc';

    bool esLocal = false;
    if (cat.isNotEmpty) {
      esLocal =
          (cat == 'locales' ||
          cat == 'local' ||
          cat == 'evento' ||
          cat == 'eventos');
    } else {
      esLocal =
          combined.contains('evento') ||
          combined.contains('fiesta') ||
          combined.contains('local') ||
          combined.contains('cumple');
    }

    final String tag = esLocal ? 'LOCAL PARA EVENTOS' : 'PISTA DE PÁDEL';
    final IconData icon = esLocal
        ? Icons.celebration_rounded
        : Icons.sports_tennis_rounded;
    final Color color = esLocal ? AppTheme.partyPurple : AppTheme.accent;

    return {'tag': tag, 'icon': icon, 'color': color, 'esLocal': esLocal};
  }

  List<Map<String, dynamic>> get _espaciosFiltrados {
    return _espacios.where((e) {
      final nombre = (e['nombre'] ?? '').toString().toLowerCase();
      final ubicacion = (e['ubicacion'] ?? '').toString().toLowerCase();
      final descripcion = (e['descripcion'] ?? '').toString().toLowerCase();
      final query = _busqueda.toLowerCase();

      final coincideBusqueda =
          query.isEmpty ||
          nombre.contains(query) ||
          ubicacion.contains(query) ||
          descripcion.contains(query);

      bool coincideCategoria = true;
      final visual = _obtenerInfoVisual(e);
      final bool esLocal = visual['esLocal'] as bool;

      if (_categoriaSeleccionada == 'Locales & Eventos') {
        coincideCategoria = esLocal;
      } else if (_categoriaSeleccionada == 'Pádel & Tenis') {
        coincideCategoria = !esLocal;
      }

      return coincideBusqueda && coincideCategoria;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final String nombre =
        widget.usuario['nombre'] ??
        widget.usuario['nombre_completo'] ??
        'Cliente';
    final String email = widget.usuario['email'] ?? '';
    final String rol = (widget.usuario['rol'] ?? 'cliente')
        .toString()
        .toLowerCase();

    final List<Widget> pages = [
      _buildExplorarTab(),
      _buildMisReservasTab(),
      _buildPerfilTab(nombre, email, rol),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF2563EB),
                    Color(0xFF10B981),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: AppTheme.voltNeon,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _currentIndex == 0
                  ? 'PLAY & BOOK'
                  : _currentIndex == 1
                  ? 'MIS RESERVAS'
                  : 'MI PERFIL',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
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
      body: SafeArea(child: pages[_currentIndex]),
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

  // --- PESTAÑA 0: EXPLORAR ESPACIOS, PISTAS Y LOCALES ---
  Widget _buildExplorarTab() {
    final filtrados = _espaciosFiltrados;

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _cargarEspacios,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Hero Banner Vívido estilo Playtomic (Deportes, Canchas, Locales & Eventos)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF172554), // Deep athletic navy
                    Color(0xFF1E40AF), // Cobalt
                    Color(0xFF2563EB), // Electric Royal Blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Marca de agua geométrica en ángulo estilo Playtomic
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Transform.rotate(
                        angle: -0.28,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 32,
                            ),
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -40,
                      child: Transform.rotate(
                        angle: -0.28,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.voltNeon.withValues(alpha: 0.08),
                              width: 20,
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),

                    // Contenido del Banner
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tag superior tipo píldora
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.voltNeon.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: AppTheme.voltNeon,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'PISTAS, LOCALES & ESPACIOS',
                                  style: TextStyle(
                                    color: AppTheme.voltNeon,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Título estilo Playtomic con contraste lima-flúor
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                                letterSpacing: -0.6,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                              children: [
                                TextSpan(text: 'Encuentra '),
                                TextSpan(
                                  text: 'pistas y locales\n',
                                  style: TextStyle(color: AppTheme.voltNeon),
                                ),
                                TextSpan(text: 'cerca de ti'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtítulo
                          Text(
                            'Reserva pistas de pádel, locales para eventos privados, terrazas y salas en segundos.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Barra de búsqueda en pastilla oscura estilo Playtomic
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _busqueda = val;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'nombre, direccion...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13.5,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppTheme.voltNeon,
                                  size: 20,
                                ),
                                suffixIcon: _busqueda.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _busqueda = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                fillColor: const Color.fromARGB(0, 212, 13, 13),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 14),

                          // Atajos rápidos estilo chip sobre el banner
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildHeroQuickPill(
                                  icon: Icons.explore_rounded,
                                  label: 'Todos',
                                  categoria: 'Todos',
                                ),
                                const SizedBox(width: 8),
                                _buildHeroQuickPill(
                                  icon: Icons.sports_tennis_rounded,
                                  label: 'Pádel & Canchas',
                                  categoria: 'Pádel & Tenis',
                                ),
                                const SizedBox(width: 8),
                                _buildHeroQuickPill(
                                  icon: Icons.celebration_rounded,
                                  label: 'Locales & Eventos',
                                  categoria: 'Locales & Eventos',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Selector de Categorías (Deportes, Locales, Fiestas, Terrazas)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categorias.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categorias[index];
                  final isSelected = _categoriaSeleccionada == cat['nombre'];
                  final Color catColor = cat['color'] as Color;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _categoriaSeleccionada = cat['nombre'];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? catColor : AppTheme.border,
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: catColor.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : catColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['nombre'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Encabezado de la lista
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lugares y Espacios (${filtrados.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (_cargandoEspacios)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accent,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 4. Listado con Imágenes en Alta Definición y Estilo Playtomic
          if (_cargandoEspacios && _espacios.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            )
          else if (filtrados.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.holiday_village_outlined,
                          size: 52,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'No encontramos espacios en esta categoría',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _busqueda.isNotEmpty
                            ? 'Prueba con otro término de búsqueda.'
                            : 'Pronto se publicarán nuevos locales y pistas.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final e = filtrados[index];
                  return _buildVenueCard(e);
                }, childCount: filtrados.length),
              ),
            ),
        ],
      ),
    );
  }

  // Tarjeta de Espacio con Fotografía Real (Estilo Playtomic, sin datos inventados)
  Widget _buildVenueCard(Map<String, dynamic> e) {
    final nombre = e['nombre'] ?? 'Espacio';
    final ubicacion = (e['ubicacion'] ?? 'Ubicación céntrica')
        .toString()
        .trim();
    final capacidad = e['capacidad_maxima'] ?? '4';
    final precio = e['precio_por_dia'] ?? '0';
    final desc = (e['descripcion'] ?? '').toString().trim();

    final visual = _obtenerInfoVisual(e);
    final String tag = visual['tag'] as String;
    final IconData icon = visual['icon'] as IconData;
    final Color color = visual['color'] as Color;

    final String? rawImg = e['imagen_url']?.toString().trim();
    final bool tieneFoto = rawImg != null && rawImg.isNotEmpty && rawImg.startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _abrirModalReserva(e),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. CABECERA CON FOTO REAL O BANNER VISUAL ---
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(21),
                    ),
                    child: tieneFoto
                        ? Image.network(
                            rawImg,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) {
                              return Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      color.withValues(alpha: 0.8),
                                      color,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    icon,
                                    size: 54,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                height: 180,
                                color: AppTheme.surfaceSubtle,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withValues(alpha: 0.7),
                                  color,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                  ),

                  // Sombra / Gradiente sobre la foto para contraste
                  if (tieneFoto)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(21),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                  // Badge de Categoría (Arriba a la izquierda)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: Colors.white, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Precio flotante sobre la foto (Abajo a la derecha)
                  Positioned(
                    bottom: 12,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$precio€',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const TextSpan(
                              text: ' / sesión',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // --- 2. CONTENIDO Y DETALLES DEL LUGAR ---
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 15,
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

                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Chips de características (ÚNICAMENTE DATOS REALES DE LA BD)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildFeatureChip(
                          Icons.people_outline_rounded,
                          'Hasta $capacidad pers',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Botón de Reserva Vívido
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => _abrirModalReserva(e),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.calendar_month_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Consultar Fechas y Reservar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroQuickPill({
    required IconData icon,
    required String label,
    required String categoria,
  }) {
    final isSelected = _categoriaSeleccionada == categoria;
    return GestureDetector(
      onTap: () {
        setState(() {
          _categoriaSeleccionada = isSelected ? 'Todos' : categoria;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.voltNeon
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.voltNeon
                : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF0F172A) : Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _abrirModalReserva(Map<String, dynamic> espacio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalReservaEspacio(
        espacio: espacio,
        usuarioId: widget.usuario['id'] ?? widget.usuario['usuario_id'],
        onReservaConfirmada: _cargarDatos,
      ),
    );
  }

  Widget _buildMisReservasTab() {
    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _cargarMisReservas,
      child: _cargandoReservas
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : _misReservas.isEmpty
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
                        Icons.confirmation_number_outlined,
                        size: 48,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Aún no tienes reservas activas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Explora los espacios disponibles y reserva tu próxima pista, terraza o local.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              itemCount: _misReservas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final r = _misReservas[index];
                final lugar =
                    r['espacio_nombre'] ??
                    'Espacio #${r['evento_id'] ?? r['espacio_id']}';
                final fecha = (r['fecha'] ?? r['fecha_inicio'] ?? '')
                    .toString()
                    .split('T')
                    .first;
                final franja = r['franja_horaria'] ?? '';
                final estado = (r['estado'] ?? 'pendiente')
                    .toString()
                    .toLowerCase();

                Color badgeColor = AppTheme.warning;
                Color badgeBg = const Color(0xFFFEF3C7);
                String estadoTexto = 'PENDIENTE';

                if (estado == 'confirmada' ||
                    estado == 'reservado' ||
                    estado == 'aprobada') {
                  badgeColor = AppTheme.success;
                  badgeBg = const Color(0xFFDCFCE7);
                  estadoTexto = 'CONFIRMADA';
                } else if (estado == 'cancelada' || estado == 'rechazado') {
                  badgeColor = AppTheme.danger;
                  badgeBg = const Color(0xFFFEE2E2);
                  estadoTexto = 'CANCELADA';
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lugar,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reserva #${r['id'] ?? index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                estadoTexto,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_available_rounded,
                                size: 16,
                                color: AppTheme.electricBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                fecha,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (franja.isNotEmpty) ...[
                                const Spacer(),
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  franja,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (estado != 'cancelada' && estado != 'rechazado') ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _confirmarCancelarReserva(r),
                              icon: const Icon(
                                Icons.cancel_outlined,
                                size: 16,
                                color: AppTheme.danger,
                              ),
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
    );
  }

  DateTime? _obtenerFechaHoraInicio(String fechaRaw, String franjaRaw) {
    try {
      final fechaLimpia = fechaRaw.split('T').first.trim();
      final partesFecha = fechaLimpia.split('-');
      final year = int.parse(partesFecha[0]);
      final month = int.parse(partesFecha[1]);
      final day = int.parse(partesFecha[2]);

      int hour = 9;
      int minute = 0;
      if (franjaRaw.contains(':')) {
        final inicio = franjaRaw.split('-').first.trim();
        final partesHora = inicio.split(':');
        hour = int.parse(partesHora[0]);
        minute = int.parse(partesHora[1]);
      }

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmarCancelarReserva(Map<String, dynamic> r) async {
    final reservaId = r['id'];
    if (reservaId == null) return;

    final fecha = (r['fecha'] ?? r['fecha_inicio'] ?? '').toString();
    final franja = (r['franja_horaria'] ?? '').toString();
    final inicio = _obtenerFechaHoraInicio(fecha, franja);
    final now = DateTime.now();

    final bool conMargen = inicio != null
        ? inicio.difference(now).inMinutes >= (12 * 60)
        : true;

    final int horasRestantes = inicio != null
        ? inicio.difference(now).inHours
        : 99;

    final confirm = await showDialog<bool>(
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conMargen
                  ? 'Faltan más de 12 horas ($horasRestantes h) para el inicio de tu turno.\n\n'
                        '✓ Se liberará el espacio para otros socios.\n'
                        '✓ Se te reembolsará el 100% del importe abonado.'
                  : '⚠️ ¡Aviso de cancelación tardía! Faltan menos de 12 horas para el inicio.\n\n'
                        '✓ El espacio quedará liberado para otros socios o lista de espera.\n'
                        '✗ NO se emitirá reembolso económico según la política de 12h del club.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: conMargen
                    ? AppTheme.textPrimary
                    : const Color(0xFF92400E),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Volver',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: conMargen ? AppTheme.accent : AppTheme.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              conMargen ? 'Confirmar y Reembolsar' : 'Cancelar sin reembolso',
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _cargandoReservas = true);
      final resp = await _authService.cancelarReserva(reservaId);
      await _cargarMisReservas();

      if (!mounted) return;

      final bool exito = resp['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exito
                ? (conMargen
                      ? '✓ Reserva cancelada. Espacio liberado y 100% reembolsado.'
                      : 'Espacio liberado para otros socios. Sin derecho a reembolso (<12h).')
                : (resp['mensaje'] ?? 'No se pudo cancelar la reserva'),
          ),
          backgroundColor: exito
              ? (conMargen ? const Color(0xFF059669) : AppTheme.warning)
              : AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // --- PESTAÑA 2: PERFIL DE USUARIO ---
  Widget _buildPerfilTab(String nombre, String email, String rol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de Identidad
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accentVivid, AppTheme.electricBlue],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.voltNeon.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.voltNeon.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'MIEMBRO VIP • ${rol.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.voltNeon,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Acciones y opciones de cuenta
          const Text(
            'Mi Cuenta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          _buildProfileTile(
            icon: Icons.person_outline_rounded,
            title: 'Datos Personales',
            subtitle: 'Nombre, teléfono y preferencias',
          ),
          _buildProfileTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notificaciones y Recordatorios',
            subtitle: 'Avisos de reservas y partidos',
          ),
          _buildProfileTile(
            icon: Icons.shield_outlined,
            title: 'Seguridad y Contraseña',
            subtitle: 'Gestiona el acceso a tu cuenta',
          ),
          _buildProfileTile(
            icon: Icons.help_outline_rounded,
            title: 'Soporte y Ayuda',
            subtitle: 'Preguntas frecuentes y atención al cliente',
          ),

          const SizedBox(height: 20),

          // Botón Cerrar Sesión
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
              icon: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppTheme.danger,
              ),
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.danger, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textMuted,
          size: 20,
        ),
        onTap: () {},
      ),
    );
  }
}
