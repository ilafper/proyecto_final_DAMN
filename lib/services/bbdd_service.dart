import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Dirección IP de tu ordenador en la red local para conectar con tu Samsung Galaxy
  static const String baseUrl = 'http://192.168.1.131:5500/api/auth';

  // Cabeceras estándar para peticiones JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // Guardamos el token en memoria una vez logueado
  static String? tokenActual;

  // 1. INICIAR SESIÓN (LOGIN)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Guardamos el token en nuestra clase
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
      return {
        'success': false,
        'mensaje': 'No se pudo conectar con el servidor: $e',
      };
    }
  }

  // 2. REGISTRAR USUARIO (REGISTRO)
  Future<Map<String, dynamic>> registro({
    required String email,
    required String password1,
    required String password2,
    String nombre = '',
    String rol = 'cliente',
  }) async {
    final url = Uri.parse('$baseUrl/registro');

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
      return {
        'success': false,
        'mensaje': 'No se pudo conectar con el servidor: $e',
      };
    }
  }
}
