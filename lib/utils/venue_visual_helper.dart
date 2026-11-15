import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VenueTypeInfo {
  final String tag;
  final IconData icon;
  final Color color;
  final Color bg;
  final String defaultImageUrl;
  final List<String> features;

  const VenueTypeInfo({
    required this.tag,
    required this.icon,
    required this.color,
    required this.bg,
    required this.defaultImageUrl,
    required this.features,
  });
}

class VenueVisualHelper {
  // Imágenes en alta definición directas de Unsplash con temas reales
  static const String imgEventos =
      'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=900&q=80';
  static const String imgPadel =
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?auto=format&fit=crop&w=900&q=80';
  static const String imgTerraza =
      'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=900&q=80';
  static const String imgFutbol =
      'https://images.unsplash.com/photo-1529900245534-47fbf02a44dd?auto=format&fit=crop&w=900&q=80';
  static const String imgFiesta =
      'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=900&q=80';
  static const String imgFitness =
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=900&q=80';
  static const String imgReuniones =
      'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=900&q=80';

  static VenueTypeInfo getTypeInfo(Map<String, dynamic> espacio) {
    final nombre = (espacio['nombre'] ?? '').toString().toLowerCase();
    final desc = (espacio['descripcion'] ?? '').toString().toLowerCase();
    final combined = '$nombre $desc';

    if (combined.contains('terraza') || combined.contains('rooftop') || combined.contains('chill')) {
      return const VenueTypeInfo(
        tag: 'TERRAZA & ROOFTOP',
        icon: Icons.deck_rounded,
        color: AppTheme.energyOrange,
        bg: Color(0xFFFFF7ED),
        defaultImageUrl: imgTerraza,
        features: ['Vistas 360°', 'Zona Cóctel', 'Música'],
      );
    } else if (combined.contains('evento') ||
        combined.contains('fiesta') ||
        combined.contains('celebracion') ||
        combined.contains('local') ||
        combined.contains('cumpleaños')) {
      return const VenueTypeInfo(
        tag: 'LOCAL PARA EVENTOS',
        icon: Icons.celebration_rounded,
        color: AppTheme.partyPurple,
        bg: Color(0xFFF5F3FF),
        defaultImageUrl: imgEventos,
        features: ['Equipo Sonido', 'Climatizado', 'Luces LED'],
      );
    } else if (combined.contains('futbol') || combined.contains('fútbol') || combined.contains('campo')) {
      return const VenueTypeInfo(
        tag: 'CÉSPED FÚTBOL',
        icon: Icons.sports_soccer_rounded,
        color: AppTheme.electricBlue,
        bg: Color(0xFFEFF6FF),
        defaultImageUrl: imgFutbol,
        features: ['Césped Pro', 'Vestuarios', 'Focos LED'],
      );
    } else if (combined.contains('fitness') || combined.contains('gym') || combined.contains('gimnasio') || combined.contains('yoga')) {
      return const VenueTypeInfo(
        tag: 'ESTUDIO FITNESS',
        icon: Icons.fitness_center_rounded,
        color: Color(0xFF0284C7),
        bg: Color(0xFFF0F9FF),
        defaultImageUrl: imgFitness,
        features: ['Espejos Pro', 'Suelo Técnico', 'Sonido Hi-Fi'],
      );
    } else if (combined.contains('sala') || combined.contains('reunion') || combined.contains('reunión') || combined.contains('oficina')) {
      return const VenueTypeInfo(
        tag: 'SALA POLIVALENTE',
        icon: Icons.meeting_room_rounded,
        color: Color(0xFF475569),
        bg: Color(0xFFF1F5F9),
        defaultImageUrl: imgReuniones,
        features: ['Pantalla / Proyector', 'WiFi 6', 'Climatizado'],
      );
    } else {
      // Por defecto o si es pista deportiva (Pádel, Tenis)
      return const VenueTypeInfo(
        tag: 'PISTA DE PÁDEL',
        icon: Icons.sports_tennis_rounded,
        color: AppTheme.accent,
        bg: Color(0xFFECFDF5),
        defaultImageUrl: imgPadel,
        features: ['Cristal Panorámico', 'Luz LED Pro', 'Oficial'],
      );
    }
  }

  static String getImageUrl(Map<String, dynamic> espacio) {
    final customUrl = espacio['imagen_url'] ?? espacio['foto'] ?? espacio['image_url'];
    if (customUrl != null && customUrl.toString().startsWith('http')) {
      return customUrl.toString();
    }
    return getTypeInfo(espacio).defaultImageUrl;
  }
}
