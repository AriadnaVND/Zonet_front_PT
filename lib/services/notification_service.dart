// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../models/notification.dart'; // Crearemos este modelo en el siguiente paso

// =========================================================================
// 1. CONFIGURACIÓN GLOBAL DE NOTIFICACIONES LOCALES
// Estas variables deben estar fuera de la clase.
// =========================================================================

// Canal de notificaciones de Android para notificaciones de "alta importancia"
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title visible al usuario en ajustes de Android
  description:
      'Este canal se utiliza para notificaciones importantes de Zoonet.',
  importance:
      Importance.max, // Nivel de importancia máximo para heads-up notification
);

// Plugin para mostrar notificaciones locales (necesario cuando la app está abierta)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  final AuthService _authService = AuthService();

  String _getNotificationBaseUrl() {
    // Reutiliza la lógica base y apunta a /api/notifications
    return _authService.getPetBaseUrl().replaceFirst(
      '/api/pets',
      '/api/notifications',
    );
  }

  String _getUserProfileBaseUrl() {
    // Apunta al controlador de usuarios, donde se debe registrar el token
    return _authService.getPetBaseUrl().replaceFirst(
      '/api/pets',
      '/api/user/profile', // Corregido para coincidir con el @RequestMapping del backend
    );
  }

  // 1. Obtener todas las notificaciones del usuario (GET /api/notifications/{userId})
  Future<List<AppNotification>> fetchNotifications(int userId) async {
    final url = Uri.parse('${_getNotificationBaseUrl()}/$userId');

    // Obtener JWT para la autenticación de la solicitud
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');

    final headers = jwtToken != null
        ? {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $jwtToken',
          }
        : {'Content-Type': 'application/json; charset=UTF-8'};

    try {
      final response = await http.get(url, headers: headers);

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

  // =========================================================================
  // MÉTODOS NUEVOS PARA NOTIFICACIONES PUSH (FCM)
  // =========================================================================

  /// Inicializa la configuración de notificaciones: permisos, listeners y token.
  Future<void> initNotifications() async {
    // 1. Solicitar Permisos
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(
          alert: true,
          badge: true,
          sound: true,
          // Configuración de permisos para iOS/macOS
          announcement: false,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
        );

    print(
      'Permiso de usuario para Notificaciones Push: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Configuración de notificaciones locales (solo necesario para manejar el FORGEGROUND)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings(
            '@mipmap/ic_launcher',
          ); // Usa el ícono de la app

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        // Manejar el click en la notificación (solo para notificaciones locales/Foreground)
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // Lógica para navegar al hacer clic en la notificación local (si la app está en primer plano)
          print('Local Notification click payload: ${response.payload}');
          // Ejemplo de navegación si usas GetX o Provider para el contexto:
          // if (response.payload != null) { // Aquí puedes parsear el JSON de payload
          //   Navigator.of(context).pushNamed('/ruta_notificacion');
          // }
        },
      );

      // 3. Obtener y enviar Token
      await _getAndSendFCMToken();

      // 4. Manejo de mensajes en primer plano (Foreground)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Manejo de interacción de notificación (al hacer click cuando estaba en background/cerrada)
      // Esto maneja cuando el usuario pulsa la notificación para abrir la app.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // 6. Configuración de presentación en Foreground (iOS/macOS)
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Obtiene el token de FCM del dispositivo y lo envía al backend.
  Future<void> _getAndSendFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId'); // Asumo que guardas el userId
      final jwtToken = prefs.getString('jwtToken'); // Asumo que guardas el JWT

      if (userId != null && jwtToken != null) {
        // 🟢 CORRECCIÓN 2: Usar la nueva función de URL y el endpoint correcto (/api/user/profile/{userId}/fcm-token)
        final url = Uri.parse('${_getUserProfileBaseUrl()}/$userId/fcm-token');

        print('URL DE REGISTRO FCM: $url');

        try {
          // 🟢 CORRECCIÓN 3: Cambiar http.post por http.put (El backend usa @PutMapping)
          final response = await http.put(
            url,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $jwtToken', // Autenticación con JWT
            },
            // 🟢 CORRECCIÓN 4: Cambiar la clave de 'fcmToken' a 'token' (El backend espera 'token')
            body: jsonEncode({'token': token}),
          );

          if (response.statusCode == 200) {
            print('Token FCM enviado al backend exitosamente.');
          } else {
            print(
              'FALLO CRÍTICO DE REGISTRO DE TOKEN: Código ${response.statusCode}. Respuesta: ${response.body}',
            );
          }
        } catch (e) {
          print('Excepción de Red/Conexión al enviar el token FCM: $e');
        }
      } else {
        print(
          'Advertencia: userId o jwtToken no disponibles. No se envió el token FCM.',
        );
      }
    } else {
      print(
        'Advertencia: Firebase no pudo obtener el token FCM del dispositivo.',
      );
    }
  }

  /// Manejador de mensajes cuando la app está activa (Foreground).
  void _handleForegroundMessage(RemoteMessage message) {
    print('Mensaje en primer plano recibido: ${message.notification?.title}');

    // Usa flutter_local_notifications para mostrar la notificación.
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon:
                android.smallIcon ??
                '@mipmap/ic_launcher', // Se recomienda usar un icono personalizado
          ),
        ),
        payload: jsonEncode(
          message.data,
        ), // Pasa la data para que se use al hacer click
      );
    }
  }

  /// Manejador de interacción (click) en la notificación cuando la app está en background/terminada.
  void _handleNotificationClick(RemoteMessage message) {
    print('Notificación push clickeada: ${message.data}');
    // **Importante:** Aquí debes implementar la lógica para navegar a una pantalla
    // específica (ej: la lista de notificaciones, o detalles de una mascota).
    // Esto generalmente requiere acceder al Navigator a través de un Context o
    // un State global (como con GetX o Riverpod).
  }

  // 💡 NOTA: Las preferencias de configuración (Recibir Notificaciones, Reacciones)
  // no tienen endpoints definidos en el backend, por lo que serán estáticas
  // en el frontend hasta que se añadan los endpoints PUT.
}
