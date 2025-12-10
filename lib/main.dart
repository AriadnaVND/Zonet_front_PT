import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/welcome_screen.dart'; // Importar la nueva pantalla de registro

// Configuración global para el manejo de mensajes en segundo plano (Background)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Manejo de mensaje en segundo plano: ${message.messageId}');
}

// Configuración de Local Notifications
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Configuración de notificaciones locales para Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // 4. Configuración de permisos de iOS y web
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // 5. Configuración de la barra de navegación(ocultar)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    // Si quieres ocultar solo una:
    // overlays: [SystemUiOverlay.bottom], // Oculta solo la barra de navegación
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoonet Front',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Usamos el color primario de tu diseño como semilla para la paleta de colores
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00ADB5)),
        useMaterial3: true,
      ),

      home: const WelcomeScreen(),
    );
  }
}

// Las otras clases como MyHomePage, etc. pueden ser eliminadas o mantenidas, 
// pero RegisterScreen es ahora el punto de entrada.