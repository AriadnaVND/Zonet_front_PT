// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';
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

  String getPetBaseUrl() => '${_getBaseUrl()}/api/pets';
  String getSubscriptionsBaseUrl() => '${_getBaseUrl()}/api/subscriptions';

  final String _registerEndpoint = '/api/auth/register';
  final String _loginEndpoint = '/api/auth/login';

  // Metodo para construir URL completas de imágenes
  String buildFullImageUrl(String photoUrlPath) {
    if (photoUrlPath.startsWith('http')) {
      return photoUrlPath;
    }
    return _getBaseUrl() + photoUrlPath;
  }

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

  // 2. Registro Mascota y Plan (Multipart)
  // Endpoint: POST /api/pets/{userId}/register
  Future<Map<String, dynamic>> registerPetAndPlan(
    int userId,
    String petName,
    String planType,
    File photo,
  ) async {
    final url = Uri.parse('${getPetBaseUrl()}/$userId/register');

    var request = http.MultipartRequest('POST', url);

    request.fields['petName'] = petName;
    request.fields['planType'] = planType;

    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        photo.path,
        filename: 'pet_photo_$userId.jpg',
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    // 💡 CORRECCIÓN CLAVE: Asegurarse de que el cuerpo NO esté vacío antes de decodificar.
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        // El backend debería devolver un cuerpo, pero si está vacío, devolvemos un JSON de éxito.
        return {
          'message':
              'Mascota registrada, pero el servidor no devolvió detalles.',
          'planType': planType,
        };
      }
    } else {
      // Manejar el error de forma explícita
      String errorMessage = 'Fallo en la conexión.';
      try {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        errorMessage =
            errorBody['message'] ??
            'Fallo en el registro. Código: ${response.statusCode}';
      } catch (_) {
        errorMessage =
            'Error: Código ${response.statusCode}. Respuesta no es JSON.';
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> selectPlan(int userId, String planType) async {
    final url = Uri.parse('${getSubscriptionsBaseUrl()}/$userId');

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'planType': planType}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          return jsonDecode(utf8.decode(response.bodyBytes));
        } else {
          return {
            'message': 'Plan procesado, pero el servidor no devolvió detalles.',
            'planType': planType,
          };
        }
      } else {
        String errorMessage = 'Fallo al procesar el plan.';
        try {
          final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
          errorMessage =
              errorBody['message'] ??
              'Fallo en la API. Código: ${response.statusCode}';
        } catch (_) {
          errorMessage =
              'Error: Código ${response.statusCode}. Respuesta no es JSON.';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Fallo de conexión al procesar el plan: ${e.toString()}');
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
        final errorMessage =
            errorBody['message'] ??
            'Credenciales incorrectas o error de servidor.';
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
