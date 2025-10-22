import 'package:flutter/material.dart';
import '../auth/login_screen.dart'; // Para redirigir al Login después de la compra
import '../../services/auth_service.dart'; // Para la lógica de negocio

class PaymentScreen extends StatefulWidget {
  final int userId;

  const PaymentScreen({super.key, required this.userId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderNameController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Lógica para simular el procesamiento de la compra
  Future<void> _processPurchase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Llama al backend para activar el plan Premium (simulando que el pago fue exitoso)
      // Endpoint: POST /api/subscriptions/{userId}
      await _authService.selectPlan(widget.userId, 'PREMIUM');

      _showSnackbar('Compra procesada y plan Premium activado. ¡Inicia sesión!', isError: false);
      if (mounted) {
        // Redirige al Login después de una compra exitosa
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnackbar('Error al procesar la compra: $errorMessage', isError: true);
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

  // --- Widget de campo de texto personalizado para el formulario ---
  Widget _buildPaymentTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: isPassword,
        keyboardType: keyboardType,
        maxLength: maxLength,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          hintText: hintText,
          counterText: "", // Ocultar contador de longitud
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Color(0xFF00ADB5), width: 2)),
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.black : Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.black : Colors.grey[700])),
        ],
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Método de Pago', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Tarjeta de Crédito o Débito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // Campos del formulario de tarjeta
              _buildPaymentTextField(controller: _cardHolderNameController, hintText: 'Nombre Del Titular', icon: Icons.person, validator: (value) => value!.isEmpty ? 'Ingresa el nombre del titular' : null),
              _buildPaymentTextField(controller: _cardNumberController, hintText: 'xxxx xxxx xxxx xxxx', icon: Icons.credit_card, keyboardType: TextInputType.number, maxLength: 19, validator: (value) => value!.length < 16 ? 'Número de tarjeta inválido' : null),
              Row(
                children: [
                  Expanded(child: _buildPaymentTextField(controller: _expiryDateController, hintText: 'MM/AA', icon: Icons.calendar_today, keyboardType: TextInputType.number, maxLength: 5, validator: (value) => value!.length < 5 ? 'Fecha inválida' : null)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPaymentTextField(controller: _cvvController, hintText: 'CVV', icon: Icons.lock, keyboardType: TextInputType.number, isPassword: true, maxLength: 3, validator: (value) => value!.length < 3 ? 'CVV inválido' : null)),
                ],
              ),
              const SizedBox(height: 30),

              // Resumen de la compra
              const Text('Resumen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 20),
              _buildSummaryRow('Artículo:', 'Premium individual'),
              _buildSummaryRow('Mensual:', 'S/15.00 Al Mes'),
              const Divider(height: 20),
              _buildSummaryRow('Total Ahora:', 'PEN 15.00', isTotal: true),
              const SizedBox(height: 10),
              const Text(
                'Por Esto, Medios, Autorizacón A, Donar A, Cubierto De Forma Automáliza Cada, Mes, Hasta Que Canciones La Suscripción. Aplicable En Los Términos Y Condiciones. Los Precios Y La Disponibilidad Pueden Cambiar Sin Previo Aviso. Pagos Automáticos. Comprar. Impuestos. Tarifas. Términos. Condiciones. Puede Consultar Los Términos Y Condiciones Antes. De Comprar. Cargos Adicionales.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 30),

              // Botón COMPLETAR COMPRA
              ElevatedButton(
                onPressed: _isLoading ? null : _processPurchase,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('COMPLETAR COMPRA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
