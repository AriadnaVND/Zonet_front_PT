// lib/dto/support_ticket_request.dart (O donde almacenes tus DTOs)
class SupportTicketRequest {
  final int userId;
  final String description;

  SupportTicketRequest({required this.userId, required this.description});

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'description': description};
  }
}
