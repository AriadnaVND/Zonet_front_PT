import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart'; // Importar la nueva pantalla de registro

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoonet Front',
      theme: ThemeData(
        // Usamos el color primario de tu diseño como semilla para la paleta de colores
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00ADB5)),
        useMaterial3: true,
      ),
      // Mostrar la pantalla de registro como pantalla inicial
      home: const WelcomeScreen(),
    );
  }
}

// Las otras clases como MyHomePage, etc. pueden ser eliminadas o mantenidas, 
// pero RegisterScreen es ahora el punto de entrada.