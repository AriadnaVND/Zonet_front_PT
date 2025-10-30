import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/zone.dart';
import 'auth_service.dart';

class ZoneService {
  final AuthService _authService = AuthService();

  String _getSafeZoneBaseUrl() {
    // Tomamos la URL base pública del servicio de mascotas (ej: http://ip:8080/api/pets)
    final baseUrl = _authService.getPetBaseUrl().replaceFirst('/api/pets', '/api/location/safezones');
    return baseUrl;
  }

  // 1. Obtener todas las zonas de un usuario (GET /api/location/safezones/{userId})
  Future<List<Zone>> fetchSafeZones(int userId) async {
    final url = Uri.parse('${_getSafeZoneBaseUrl()}/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Zone.fromJson(json)).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['message'] ?? 'Fallo al cargar zonas seguras.',
        );
      }
    } catch (e) {
      throw Exception('Fallo de conexión al cargar zonas: ${e.toString()}');
    }
  }

  // 2. Crear una nueva zona segura (POST /api/location/safezones)
  Future<void> createSafeZone(Zone zone) async {
    final url = Uri.parse(_getSafeZoneBaseUrl());

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(zone.toJson()),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        // Captura el mensaje de límite de zona para usuarios FREE desde SafeZoneService.java
        throw Exception(
          errorBody['message'] ?? 'Fallo al crear la zona segura.',
        );
      }
    } catch (e) {
      throw Exception('Fallo de conexión al crear zona: ${e.toString()}');
    }
  }

  // 3. Eliminar una zona (DELETE /api/location/safezones/{id})
  Future<void> deleteSafeZone(int zoneId) async {
    final url = Uri.parse('${_getSafeZoneBaseUrl()}/$zoneId');

    try {
      final response = await http.delete(url);

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['message'] ?? 'Fallo al eliminar zona segura.',
        );
      }
    } catch (e) {
      throw Exception('Fallo de conexión al eliminar zona: ${e.toString()}');
    }
  }
}
