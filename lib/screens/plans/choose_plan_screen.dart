import 'package:flutter/material.dart';
import 'dart:io';
import '../auth/login_screen.dart';
import 'payment_screen.dart';
import '../../services/auth_service.dart';

class ChoosePlanScreen extends StatefulWidget {
  final int userId;
  final String petName;
  final File imageFile; // Archivo de la foto de la mascota

  const ChoosePlanScreen({
    super.key,
    required this.userId,
    required this.petName,
    required this.imageFile,
  });

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _selectPlan(String planType) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Registrar Mascota y Plan en el backend (esta es la llamada final de registro)
      await _authService.registerPetAndPlan(
        widget.userId,
        widget.petName,
        planType,
        widget.imageFile,
      );

      // 2. Ejecutar la lógica específica del plan después del registro exitoso
      if (planType == 'FREE') {
        _showSnackbar(
          'Plan Gratuito activado. ¡Inicia sesión para comenzar!',
          isError: false,
        );
        if (mounted) {
          // Redirige a Login y borra el historial
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        // PREMIUM
        _showSnackbar(
          'Mascota registrada. Redirigiendo a pago para activar Premium.',
          isError: false,
        );
        if (mounted) {
          // Navega a la pantalla de pago
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(userId: widget.userId),
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnackbar('Error al seleccionar plan: $errorMessage', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : const Color(0xFF00ADB5),
        ),
      );
    }
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required List<String> features,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback? onPressed,
    required bool isFree,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              price,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: isFree ? const Color(0xFF00ADB5) : Colors.amber[700],
              ),
            ),
            const Divider(height: 30, thickness: 1),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: isFree ? const Color(0xFF00ADB5) : Colors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            // Regresar a la pantalla de foto para permitir edición
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Elige Tu Plan!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Selecciona El Nivel De Protección Para Tu Mascota',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Tarjeta de Plan Gratuito
            _buildPlanCard(
              context,
              title: 'Plan Gratuito',
              price: 'S/0.0',
              features: [
                'Seguimiento Básico',
                '1 Zona Segura',
                'Acceso Limitado A La Comunidad',
              ],
              buttonText: 'PLAN GRATUITO',
              buttonColor: primaryColor,
              onPressed: () => _selectPlan(
                'FREE',
              ), // Llamada a la función con el tipo de plan
              isFree: true,
            ),
            const SizedBox(height: 20),

            // Tarjeta de Plan Premium
            _buildPlanCard(
              context,
              title: 'Plan Premium',
              price: 'S/15.0',
              features: [
                'Seguimiento En Tiempo Real',
                'Zonas Seguras Ilimitadas',
                'Alertas Avanzadas De Vía',
                'Acceso Completo A La Comunidad',
                'Historial De Rutas',
              ],
              buttonText: 'PLAN PREMIUM',
              buttonColor: const Color(0xFFE57373),
              onPressed: () => _selectPlan(
                'PREMIUM',
              ), // Llamada a la función con el tipo de plan
              isFree: false,
            ),

            const SizedBox(height: 30),
            const Text(
              'Fuentes Cambiar La Duración Del Plan En Cualquier Momento. Los Precios Y La Disponibilidad Pueden Cambiar Sin Previo Aviso.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
