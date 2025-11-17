// lib/services/tracker_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'auth_service.dart';
import '../models/location.dart';
import '../models/route_history_dto.dart';

class TrackerService {
  final AuthService _authService = AuthService();

  String _getTrackerBaseUrl() {
    // Apunta a /api/location/tracker, reutilizando la lógica de Auth
    return _authService.getPetBaseUrl().replaceFirst(
      '/api/pets',
      '/api/location/tracker',
    );
  }

  // 🟢 NUEVO MÉTODO: Base URL para el Historial
  String _getRouteHistoryBaseUrl() {
    return _authService.getPetBaseUrl().replaceFirst(
      '/api/pets',
      '/api/location/routes',
    );
  }

  // 1. Obtener la última ubicación de la mascota (GET /api/location/tracker/current/{petId})
  Future<PetLocation> fetchCurrentLocation(int petId) async {
    final url = Uri.parse('${_getTrackerBaseUrl()}/current/$petId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return PetLocation.fromJson(jsonResponse);
      } else {
        // Se lanza una excepción si no hay datos (404) o error
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          errorBody['message'] ?? 'No hay datos de ubicación disponibles.',
        );
      }
    } catch (e) {
      throw Exception('Fallo de conexión al rastreador: ${e.toString()}');
    }
  }

  // 🟢 NUEVO MÉTODO: Obtener el historial de rutas
  Future<RouteHistoryDTO> fetchRouteHistory(int petId, String period) async {
    final url = Uri.parse('${_getRouteHistoryBaseUrl()}/$petId?period=$period');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return RouteHistoryDTO.fromJson(jsonResponse);
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          errorBody['message'] ?? 'Fallo al cargar el historial de rutas.',
        );
      }
    } catch (e) {
      throw Exception(
        'Fallo de conexión al historial de rutas: ${e.toString()}',
      );
    }
  }
}
