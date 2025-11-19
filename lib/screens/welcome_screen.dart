// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'auth/login_screen.dart'; // Importa la pantalla de Login

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1BBCB6); // Color turquesa del diseño
    const Color darkBorderColor = Color(0xFF007E7A);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: <Widget>[
          // 1. Imagen de fondo (Persona con mascotas)
          Positioned(
            // La imagen se posiciona en la parte inferior de la pantalla
            bottom: 0,
            width: size.width,
            child: Image.asset(
              'assets/images/welcome.png', // Usa la imagen que hemos estado referenciando
              width: size.width,
              // Ajusta la altura de la imagen para que cubra la parte inferior como en el diseño
              height: size.height * 0.50,
              fit: BoxFit.cover,
            ),
          ),

          // 2. Contenido Superior (Texto y Botón)
          Positioned(
            top: size.height * 0.20, // Posicionamiento desde arriba
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
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 5.0, color: Colors.black38)],
                    ),
                  ),

                  // Subtítulo
                  const SizedBox(height: 5),
                  const Text(
                    'Vigila a Tu Mascota',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w300,),
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
                      backgroundColor: darkBorderColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        // Borde turquesa más oscuro para el efecto 'popup'
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      elevation: 10,
                    ),
                    child: const Text(
                      '¡Vamos!',
                      style: TextStyle(
                        fontSize: 22,
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
