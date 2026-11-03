import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // Dirección IP del servidor backend Node.js / Express
  static const String serverHost = 'http://192.168.1.129:5500';
  static const String baseUrl = '$serverHost/api/auth';
  static const String apiUrl = '$serverHost/api';

  // Cabeceras estándar para peticiones JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // Token guardado en memoria una vez logueado
  static String? tokenActual;

  // ==========================================
  // AUTENTICACIÓN
  // ==========================================

  // Iniciar sesión
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    debugPrint('🔵 [AuthService.login] POST -> $url');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('🟢 [AuthService.login] Status: ${response.statusCode} | Body: ${response.body}');
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        tokenActual = data['token'];

        return {
          'success': true,
          'mensaje': data['mensaje'] ?? 'Login correcto',
          'token': data['token'],
          'usuario': data['usuario'],
        };
      } else {
        return {
          'success': false,
          'mensaje': data['mensaje'] ?? 'Credenciales incorrectas',
        };
      }
    } catch (e) {
      debugPrint('🔴 [AuthService.login] Error: $e');
      return {
        'success': false,
        'mensaje': 'No se pudo conectar con el servidor: $e',
      };
    }
  }

  // Registrar usuario
  Future<Map<String, dynamic>> registro({
    required String email,
    required String password1,
    required String password2,
    String nombre = '',
    String rol = 'cliente',
  }) async {
    final url = Uri.parse('$baseUrl/registro');
    debugPrint('🔵 [AuthService.registro] POST -> $url');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password1': password1,
          'password2': password2,
          'nombre': nombre,
          'rol': rol,
        }),
      );

      debugPrint('🟢 [AuthService.registro] Status: ${response.statusCode} | Body: ${response.body}');
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'mensaje': data['mensaje'] ?? 'Usuario registrado con éxito',
          'usuario': data['usuario'],
        };
      } else {
        return {
          'success': false,
          'mensaje': data['mensaje'] ?? 'Error al registrar',
        };
      }
    } catch (e) {
      debugPrint('🔴 [AuthService.registro] Error: $e');
      return {
        'success': false,
        'mensaje': 'No se pudo conectar con el servidor: $e',
      };
    }
  }

  // ==========================================
  // ESPACIOS (SITIOS PARA RESERVAR)
  // ==========================================

  // 1. Obtener todos los espacios
  Future<List<Map<String, dynamic>>> getEspacios() async {
    final url = Uri.parse('$apiUrl/espacios');
    debugPrint('🔵 [AuthService.getEspacios] GET -> $url');

    try {
      final response = await http.get(url, headers: _headers);
      debugPrint('🟢 [AuthService.getEspacios] Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['espacios'] != null) {
          final list = List<Map<String, dynamic>>.from(data['espacios']);
          debugPrint('✅ [AuthService.getEspacios] Se han cargado ${list.length} espacios');
          return list;
        }
      } else {
        debugPrint('⚠️ [AuthService.getEspacios] Respuesta no exitosa: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 [AuthService.getEspacios] Excepción: $e');
    }
    return [];
  }

  // 2. Crear un nuevo espacio (Para Admin)
  Future<Map<String, dynamic>> crearEspacio({
    required String nombre,
    required String descripcion,
    required String ubicacion,
    required int capacidadMaxima,
    required double precioPorDia,
    String estado = 'disponible',
  }) async {
    final url = Uri.parse('$apiUrl/espacios');
    final body = {
      'nombre': nombre,
      'descripcion': descripcion,
      'ubicacion': ubicacion,
      'capacidad_maxima': capacidadMaxima,
      'precio_por_dia': precioPorDia,
      'estado': estado,
    };
    debugPrint('🔵 [AuthService.crearEspacio] POST -> $url | Body: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      debugPrint('🟢 [AuthService.crearEspacio] Status: ${response.statusCode} | Body: ${response.body}');
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('🔴 [AuthService.crearEspacio] Excepción: $e');
      return {
        'success': false,
        'mensaje': 'Error de conexión al crear espacio: $e',
      };
    }
  }

  // ==========================================
  // RESERVAS (fecha YYYY-MM-DD y franja_horaria)
  // ==========================================

  // 1. Obtener reservas reales (soporta evento_id y usuario_id)
  Future<List<Map<String, dynamic>>> getReservas({dynamic usuarioId, dynamic eventoId}) async {
    final Map<String, String> queryParams = {};
    if (usuarioId != null) queryParams['usuario_id'] = usuarioId.toString();
    if (eventoId != null) queryParams['evento_id'] = eventoId.toString();

    final uri = Uri.parse('$apiUrl/reservas').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    debugPrint('🔵 [AuthService.getReservas] GET -> $uri');

    try {
      final response = await http.get(uri, headers: _headers);
      debugPrint('🟢 [AuthService.getReservas] Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['reservas'] != null) {
          final list = List<Map<String, dynamic>>.from(data['reservas']);
          debugPrint('✅ [AuthService.getReservas] Se han cargado ${list.length} reservas');
          return list;
        }
      } else {
        debugPrint('⚠️ [AuthService.getReservas] Respuesta no exitosa: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 [AuthService.getReservas] Excepción: $e');
    }
    return [];
  }

  // 2. Crear nueva reserva con fecha y franja_horaria (por defecto 'pendiente')
  Future<Map<String, dynamic>> crearReserva({
    required dynamic eventoId,
    required dynamic usuarioId,
    required String fecha,
    required String franjaHoraria,
    String estado = 'pendiente',
  }) async {
    final url = Uri.parse('$apiUrl/reservas');
    final body = {
      'evento_id': eventoId,
      'usuario_id': usuarioId,
      'fecha': fecha,
      'franja_horaria': franjaHoraria,
      'estado': estado,
    };
    debugPrint('🔵 [AuthService.crearReserva] POST -> $url | Body: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      debugPrint('🟢 [AuthService.crearReserva] Status: ${response.statusCode} | Body: ${response.body}');
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('🔴 [AuthService.crearReserva] Excepción: $e');
      return {
        'success': false,
        'mensaje': 'Error de conexión al reservar: $e',
      };
    }
  }

  // 3. Actualizar estado de una reserva (Aceptar: 'reservado' | Rechazar: 'rechazado')
  Future<Map<String, dynamic>> actualizarEstadoReserva({
    required dynamic reservaId,
    required String nuevoEstado,
  }) async {
    final url = Uri.parse('$apiUrl/reservas/$reservaId/estado');
    debugPrint('🔵 [AuthService.actualizarEstadoReserva] PATCH -> $url con estado: $nuevoEstado');

    try {
      final response = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({'estado': nuevoEstado}),
      );

      debugPrint('🟢 [AuthService.actualizarEstadoReserva] Status: ${response.statusCode} | Body: ${response.body}');
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('🔴 [AuthService.actualizarEstadoReserva] Error: $e');
      return {
        'success': false,
        'mensaje': 'Error de conexión al cambiar estado: $e',
      };
    }
  }
}
