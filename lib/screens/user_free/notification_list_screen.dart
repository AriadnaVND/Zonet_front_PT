// lib/screens/user_free/notification_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/pet.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart'; // Para construir URL de imagen
import 'package:timeago/timeago.dart' as timeago;

class NotificationListScreen extends StatefulWidget {
  final User user;
  final Pet pet;

  const NotificationListScreen({
    super.key,
    required this.user,
    required this.pet,
  });

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final notifs = await _notificationService.fetchNotifications(
        widget.user.id!,
      );
      setState(() {
        _notifications = notifs;
      });
    } catch (e) {
      // ❗ Capturar y guardar el error
      setState(() {
        _errorMessage =
            'Error de conexión: Por favor, verifica el backend. Detalle: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  

  // --- Widgets Auxiliares ---

  // Retorna el ícono basado en el tipo de notificación
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'LOST_ALERT':
        return Icons.warning_amber_rounded;
      case 'LOCATION':
        return Icons.location_on_outlined;
      case 'REMINDER':
        return Icons.notifications_none_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // Retorna el widget de contenido de la notificación
  Widget _buildNotificationContent(AppNotification notif) {
    const Color primaryColor = Color(0xFF00ADB5);
    final isUrgent = notif.urgencyLevel == 'HIGH';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        // Destacar si es no leída
        side: notif.isRead
            ? BorderSide.none
            : BorderSide(color: primaryColor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono o Imagen a la izquierda
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 15),
              child: notif.type == 'LOST_ALERT'
                  ? CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(
                        _authService.buildFullImageUrl(widget.pet.photoUrl),
                      ),
                      backgroundColor: Colors.grey[300],
                    )
                  : CircleAvatar(
                      radius: 25,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(
                        _getNotificationIcon(notif.type),
                        color: primaryColor,
                      ),
                    ),
            ),

            // Cuerpo del Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isUrgent
                                  ? Colors.red.shade700
                                  : Colors.black87,
                            ),
                          ),
                          // Etiqueta Urgente
                          if (isUrgent)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Urgente',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Tiempo desde la notificación
                      Text(
                        timeago.format(notif.createdAt, locale: 'es'),
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Mensaje / Subtítulo
                  Text(
                    notif.message,
                    style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),

                  // Ubicación si aplica
                  if (notif.type == 'LOST_ALERT' || notif.type == 'LOCATION')
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          // NOTA: El DTO actual no devuelve la ubicación exacta,
                          // pero la simulamos basándonos en la imagen.
                          '${notif.type == 'LOST_ALERT' ? 'Central Park' : 'Riverside Park'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          '0.3 Km',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cuenta notificaciones no leídas
    final int unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
              child: Text(
                '$unreadCount Sin Leer',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFEEEEEE),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          // ❗ Mostrar el mensaje de error si existe
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            )
          // ❗ Mostrar el mensaje si la lista está vacía (cargada exitosamente)
          : _notifications.isEmpty
          ? Center(
              child: Text(
                'No tienes notificaciones por el momento.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationContent(_notifications[index]);
                },
              ),
            ),
    );
  }
}
