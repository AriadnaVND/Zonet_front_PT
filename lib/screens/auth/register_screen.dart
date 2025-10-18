// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --- Lógica de Manejo de Registro ---
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newUser = await _authService.register(
        nameController.text,
        emailController.text,
        passwordController.text,
      );

      if (mounted) {
        _showSnackbar(
          '¡Registro exitoso! Bienvenido/a ${newUser.name}.',
          isError: false,
        );
        // Navegar a la pantalla de Login después del registro exitoso
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        // Extrae el mensaje de error para mostrarlo al usuario
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

  // --- Componente de Campo de Texto Reutilizable ---
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const Color primaryColor = Color(0xFF00ADB5); // Color turquesa del diseño

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Sección superior con la imagen y la curva
            Container(
              height: size.height * 0.40,
              width: size.width,
              decoration: const BoxDecoration(color: primaryColor),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Imagen de los animales
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/registro2.jpeg', // Reemplaza si la ruta es diferente
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

            // Contenido del formulario
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
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.grey, thickness: 1, height: 30),

                    // Subtítulo "Crear Una Cuenta:"
                    const Padding(
                      padding: EdgeInsets.only(bottom: 15.0),
                      child: Text(
                        'Crear Una Cuenta:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Campos de texto (incluyen validación básica)
                    _buildTextField(
                      controller: nameController,
                      hintText: 'Nombre',
                      icon: Icons.person,
                      validator: (value) =>
                          value!.isEmpty ? 'Ingresa tu nombre' : null,
                    ),
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          !value!.contains('@') ? 'Email inválido' : null,
                    ),
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Contraseña',
                      icon: Icons.lock,
                      isPassword: true,
                      validator: (value) =>
                          value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                    ),

                    const SizedBox(height: 30),

                    // Botón CREAR UNA CUENTA
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
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
                              'CREAR UNA CUENTA',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),

                    // Enlace "Ya Tienes Una Cuenta? Iniciar Sesión"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿Ya Tienes Una Cuenta? ',
                          style: TextStyle(fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            'Iniciar Sesión',
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
