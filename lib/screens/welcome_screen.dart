// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'auth/login_screen.dart'; // Importa la pantalla de Login

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5); // Color turquesa del diseño
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: <Widget>[
          // 1. Imagen de fondo (Persona con mascotas)
          Positioned(
            // La imagen se posiciona en la parte inferior de la pantalla
            bottom: 0,
            child: Image.asset(
              'assets/images/welcome.png', // Usa la imagen que hemos estado referenciando
              width: size.width,
              // Ajusta la altura de la imagen para que cubra la parte inferior como en el diseño
              height: size.height * 0.75,
              fit: BoxFit.cover,
            ),
          ),

          // 2. Contenido Superior (Texto y Botón)
          Positioned(
            top: size.height * 0.15, // Posicionamiento desde arriba
            width: size.width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Título principal
                  const Text(
                    '¡CUIDA A TU MEJOR AMIGO!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 5.0, color: Colors.black38)],
                    ),
                  ),

                  // Subtítulo
                  const SizedBox(height: 5),
                  const Text(
                    'Vigilar A Tu Mascota',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),

                  // Botón "¡Vamos!"
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      // Navega a la pantalla de Login (y reemplaza la pantalla actual)
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        // Borde turquesa más oscuro para el efecto 'popup'
                        side: const BorderSide(
                          color: Color(0xFF008C95),
                          width: 3,
                        ),
                      ),
                      elevation: 10,
                    ),
                    child: const Text(
                      '¡Vamos!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
