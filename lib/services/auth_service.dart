// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthService {
  // ---------------------------------------------------------------------
  // Configuración de URL para desarrollo (ajustar si es necesario)
  // ---------------------------------------------------------------------
  // Para Android Emulator, usar 10.0.2.2. Para iOS Simulator/Web/Desktop, usar localhost.
  static const String _androidEmulatorUrl = '10.0.2.2:8080';
  static const String _iosSimulatorUrl = 'localhost:8080';

  String _getBaseUrl() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 apunta al host de desarrollo en un emulador Android
      return 'http://$_androidEmulatorUrl';
    } else {
      // localhost funciona para iOS, Web, Desktop (si el backend está en la misma máquina)
      return 'http://$_iosSimulatorUrl';
    }
  }

  final String _registerEndpoint = '/api/auth/register';
  final String _loginEndpoint = '/api/auth/login';

  // ---------------------------------------------------------------------
  // Método de Registro
  // ---------------------------------------------------------------------

  /// Realiza la petición POST al endpoint de registro del backend.
  /// Lanza una excepción en caso de error de conexión o API.
  Future<User> register(String name, String email, String password) async {
    final url = Uri.parse('${_getBaseUrl()}$_registerEndpoint');

    final userToRegister = User(name: name, email: email, password: password);

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(userToRegister.toJsonForRegistration()),
      );

      if (response.statusCode == 200) {
        // Devuelve el objeto User creado por el backend (con ID y plan)
        return User.fromJson(jsonDecode(response.body));
      } else {
        // El backend responde con un error 4xx/5xx (ej: email ya registrado)
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        // Intenta extraer el mensaje de error si está disponible
        final errorMessage =
            errorBody['message'] ??
            'Fallo en el registro. Código: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Manejo de errores de red o excepciones generadas
      if (e is Exception && e.toString().contains('Exception: ')) {
        // Vuelve a lanzar la excepción de la API
        rethrow;
      }
      throw Exception(
        'No se pudo conectar al servidor. Asegúrate de que el backend esté corriendo. Error: ${e.toString()}',
      );
    }
  }

  // ---------------------------------------------------------------------
  // Nuevo Método de Login
  // ---------------------------------------------------------------------

  /// Realiza la petición POST al endpoint de login del backend.
  /// Lanza una excepción si la autenticación falla o hay un error de conexión.
  Future<User> login(String email, String password) async {
    final url = Uri.parse('${_getBaseUrl()}$_loginEndpoint');
    
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        // El backend espera email y password para el login
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Login exitoso. Devuelve el objeto User.
        return User.fromJson(jsonDecode(response.body));
      } else {
        // Login fallido (ej. contraseña incorrecta, usuario no encontrado)
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] ?? 'Credenciales incorrectas o error de servidor.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Manejo de errores de red o excepciones
      if (e is Exception && e.toString().contains('Exception: ')) {
        rethrow;
      }
      throw Exception('Fallo de conexión. Error: ${e.toString()}');
    }
  }
}
