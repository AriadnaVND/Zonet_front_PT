// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
// Importa la pantalla de registro para la navegación
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  // El diseño muestra 'Nombre', pero para el Login se debe usar 'Email' (como el AuthRequest)
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --- Lógica de Manejo de Login ---
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.login(
        emailController.text,
        passwordController.text,
      );

      if (mounted) {
        _showSnackbar('¡Bienvenido de nuevo, ${user.name}!', isError: false);
        // TODO: Navegar al Home/Dashboard y guardar la sesión del usuario
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        _showSnackbar(errorMessage, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF00ADB5),
      ),
    );
  }

  // --- Componente de Campo de Texto Reutilizable (adaptado del registro) ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
          icon: Icon(icon, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
        ),
      ),
    );
  }

  // --- UI del Login ---
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const Color primaryColor = Color(0xFF00ADB5); // Color turquesa

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Sección superior con la imagen y la curva (adaptado para el diseño de Login)
            Container(
              height: size.height * 0.40,
              width: size.width,
              decoration: const BoxDecoration(color: primaryColor),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Imagen de la persona con el perro
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/login.png', // Mantenemos esta ruta por consistencia
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Curva blanca
                  Positioned(
                    bottom: -1,
                    child: Container(
                      height: 50,
                      width: size.width,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido del formulario de Login
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 20.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Título "Comencemos!"
                    const Center(
                      child: Text(
                        'Comencemos!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Subtítulo "Iniciar Sesión"
                    const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.grey, thickness: 1, height: 30),

                    // Campos de texto: Email (usado en lugar de Nombre para login)
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Email', // Cambiado a Email
                      icon: Icons
                          .person, // Usamos el icono de persona para coincidir con el diseño
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => !value!.contains('@')
                          ? 'Ingresa un email válido'
                          : null,
                    ),

                    // Campo de Contraseña
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Contraseña',
                      icon: Icons.lock,
                      isPassword: true,
                      validator: (value) =>
                          value!.isEmpty ? 'Ingresa tu contraseña' : null,
                    ),

                    // Enlace "¿Has Olvidado Tu Contraseña?"
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 30.0),
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Implementar navegación a restablecer contraseña
                        },
                        child: const Text(
                          '¿Has Olvidado Tu Contraseña?',
                          textAlign: TextAlign
                              .left, // Alinear a la izquierda como en el diseño
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
                    ),

                    // Botón INGRESAR
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'INGRESAR',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),

                    // Enlace al Registro (Reutilizar la fila del registro)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes una cuenta? ',
                          style: TextStyle(fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Navegar a la pantalla de Registro
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Crear Cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
