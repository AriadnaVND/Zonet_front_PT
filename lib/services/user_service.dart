// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet.dart';
import '../models/user.dart';
import 'auth_service.dart';

class UserService {
  final AuthService _authService = AuthService();

  String _getUserProfileBaseUrl() {
    // Apunta a /api/user/profile
    return _authService.getPetBaseUrl().replaceFirst(
      '/api/pets',
      '/api/user/profile', // Endpoint del UserController.java
    );
  }

  // Obtiene los datos de la mascota de un usuario
  Future<Pet> fetchPetByUserId(int userId) async {
    final url = Uri.parse('${_authService.getPetBaseUrl()}/user/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final petData = jsonDecode(response.body);
        // El backend debe retornar la mascota, con su 'photoUrl' real de la carpeta 'uploads'.
        return Pet.fromJson(petData);
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['message'] ??
            'Fallo al obtener datos de la mascota. Código: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(
        'Fallo de conexión al obtener datos de la mascota: ${e.toString()}',
      );
    }
  }

  // Actualiza el perfil de un usuario
  Future<User> updateProfile(
    int userId, {
    String? name,
    String? email,
    String? password,
  }) async {
    final url = Uri.parse('${_getUserProfileBaseUrl()}/$userId');
    final Map<String, String> body = {};

    // Solo agregar al cuerpo si el valor no es nulo o vacío
    if (name != null && name.isNotEmpty) {
      body['name'] = name;
    }
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    if (body.isEmpty) {
      throw Exception('No hay campos para actualizar.');
    }

    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // El backend retorna el objeto User actualizado
        return User.fromJson(responseBody);
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        // Maneja errores de validación (email duplicado) o usuario no encontrado
        throw Exception(responseBody['message'] ?? responseBody.toString());
      } else {
        throw Exception(
          'Error al actualizar el perfil. Código: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Fallo de conexión al actualizar perfil: ${e.toString()}',
      );
    }
  }

  // Elimina la cuenta de un usuario
  Future<void> deleteAccount(int userId) async {
    final url = Uri.parse('${_getUserProfileBaseUrl()}/$userId');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 204) {
        // 204 No Content es la respuesta esperada
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado para eliminar.');
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          errorBody['message'] ??
              'Error al eliminar la cuenta. Código: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Fallo de conexión al eliminar cuenta: ${e.toString()}');
    }
  }
}
