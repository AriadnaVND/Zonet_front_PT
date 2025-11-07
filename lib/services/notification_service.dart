// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/notification.dart'; // Crearemos este modelo en el siguiente paso

class NotificationService {
  final AuthService _authService = AuthService();

  String _getNotificationBaseUrl() {
    // Reutiliza la lógica base y apunta a /api/notifications
    return _authService.getPetBaseUrl().replaceFirst(
      '/api/pets',
      '/api/notifications',
    );
  }

  // 1. Obtener todas las notificaciones del usuario (GET /api/notifications/{userId})
  Future<List<AppNotification>> fetchNotifications(int userId) async {
    final url = Uri.parse('${_getNotificationBaseUrl()}/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          errorBody['message'] ??
              'Fallo al cargar notificaciones: Código ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'Fallo de conexión al cargar notificaciones: ${e.toString()}',
      );
    }
  }

  // 💡 NOTA: Las preferencias de configuración (Recibir Notificaciones, Reacciones)
  // no tienen endpoints definidos en el backend, por lo que serán estáticas
  // en el frontend hasta que se añadan los endpoints PUT.
}
