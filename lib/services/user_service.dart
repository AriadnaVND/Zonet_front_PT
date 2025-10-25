// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet.dart';
import 'auth_service.dart';

class UserService {
  final AuthService _authService = AuthService();

  // 🔴 IMPORTANTE: Asume que el backend implementará un GET /api/pets/user/{userId}
  // para obtener la mascota del usuario logeado.
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
}
