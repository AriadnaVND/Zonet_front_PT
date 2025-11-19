// lib/services/support_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/support_ticket_request.dart'; // Asegúrate de que esta ruta sea correcta

class SupportService {
  final AuthService _authService = AuthService();

  String _getSupportBaseUrl() {
    return _authService.getPetBaseUrl().replaceFirst(
      '/api/pets',
      '/api/support/tickets',
    );
  }

  // POST /api/support/tickets
  Future<void> createTicket(SupportTicketRequest request) async {
    final url = Uri.parse(_getSupportBaseUrl());

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 201) {
        // HttpStatus.CREATED
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          errorBody['error'] ?? 'Fallo al crear el ticket de soporte.',
        );
      }
    } catch (e) {
      throw Exception(
        'Fallo de conexión al servicio de soporte: ${e.toString()}',
      );
    }
  }
}
