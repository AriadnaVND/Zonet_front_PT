import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/login_screen.dart'; // Para redirigir al Login después de la compra
import '../../services/auth_service.dart'; // Para la lógica de negocio

class PaymentScreen extends StatefulWidget {
  final int userId;

  const PaymentScreen({super.key, required this.userId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

// 💡 Clase utilitaria para manejar la información de la tarjeta
class CardUtils {
  static CardType getCardType(String cardNumber) {
    if (cardNumber.isEmpty) return CardType.Invalid;

    // Simplificación de patrones (se pueden añadir más)
    if (cardNumber.startsWith(RegExp(r'4'))) return CardType.Visa;
    if (cardNumber.startsWith(RegExp(r'5[1-5]'))) return CardType.Mastercard;
    if (cardNumber.startsWith(RegExp(r'3[47]'))) return CardType.Amex;

    return CardType.Invalid;
  }
}

// 💡 Enum para los tipos de tarjeta (solo para la simulación visual)
enum CardType { Visa, Mastercard, Amex, Invalid }

// 💡 Formateador para Número de Tarjeta (Añade espacios y limita)
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'\s'), '');

    // Limitar a 16 dígitos
    if (text.length > 16) {
      text = text.substring(0, 16);
    }

    // Añadir espacios cada 4 dígitos
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    final newString = buffer.toString();
    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

// 💡 Formateador para Fecha de Expiración (Añade el "/")
class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      // Añade '/' después de 2 caracteres (MM) si no es el final y no ha pasado el límite de 5
      if (nonZeroIndex % 2 == 0 &&
          nonZeroIndex != text.length &&
          nonZeroIndex < 5) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    // Limitar a 5 caracteres (MM/AA)
    if (string.length > 5) {
      string = string.substring(0, 5);
    }

    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _PaymentScreenState extends State<PaymentScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderNameController =
      TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  CardType _cardType = CardType.Invalid;

  @override
  void initState() {
    super.initState();
    // ✅ CORRECCIÓN 1: Asegurar que el listener se inicialice
    _cardNumberController.addListener(_updateCardType);
  }

  @override
  void dispose() {
    // ✅ CORRECCIÓN 2: Asegurar que el listener se remueva para evitar memory leaks
    _cardNumberController.removeListener(_updateCardType);

    _cardNumberController.dispose();
    _cardHolderNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // 💡 Función para actualizar el tipo de tarjeta (Visa, Mastercard, etc.)
  void _updateCardType() {
    final type = CardUtils.getCardType(
      _cardNumberController.text.replaceAll(' ', ''),
    );
    if (type != _cardType) {
      setState(() {
        _cardType = type;
      });
    }
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

      _showSnackbar(
        'Compra procesada y plan Premium activado. ¡Inicia sesión!',
        isError: false,
      );
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
      _showSnackbar(
        'Error al procesar la compra: $errorMessage',
        isError: true,
      );
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

  // 💡 NUEVO MÉTODO: Obtener el widget de ícono de la tarjeta
  Widget _getCardIcon() {
    switch (_cardType) {
      case CardType.Visa:
        return const Icon(
          Icons.credit_card,
          color: Colors.blue,
        ); // Icono simple de Visa
      case CardType.Mastercard:
        return const Icon(
          Icons.credit_card,
          color: Colors.orange,
        ); // Icono simple de Mastercard
      case CardType.Amex:
        return const Icon(
          Icons.credit_card,
          color: Colors.green,
        ); // Icono simple de Amex
      case CardType.Invalid:
      default:
        return Icon(Icons.credit_card, color: Colors.grey[600]);
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
    List<TextInputFormatter>? inputFormatters,
    Widget? customIcon,
  }) {
    // ... (rest of implementation is already correct)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: isPassword,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          prefixIcon: customIcon ?? Icon(icon, color: Colors.grey[600]),
          hintText: hintText,
          counterText: "", // Ocultar contador de longitud
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Color(0xFF00ADB5), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15.0,
            horizontal: 10.0,
          ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
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
        title: const Text(
          'Método de Pago',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Tarjeta de Crédito o Débito',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // Campo de Nombre Del Titular
              _buildPaymentTextField(
                controller: _cardHolderNameController,
                hintText: 'Nombre Del Titular',
                icon: Icons.person,
                validator: (value) =>
                    value!.isEmpty ? 'Ingresa el nombre del titular' : null,
              ),

              // Campo de Número de Tarjeta
              _buildPaymentTextField(
                controller: _cardNumberController,
                hintText: 'xxxx xxxx xxxx xxxx',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                maxLength: 19, // Límite para 16 dígitos + 3 espacios
                customIcon: _getCardIcon(), // Usa el ícono detectado
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Solo dígitos
                  CardNumberInputFormatter(), // Formato de espacios
                ],
                validator: (value) => value!.replaceAll(' ', '').length < 16
                    ? 'Número de tarjeta inválido'
                    : null,
              ),

              Row(
                children: [
                  Expanded(
                    // Campo de Fecha de Expiración
                    child: _buildPaymentTextField(
                      controller: _expiryDateController,
                      hintText: 'MM/AA',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ExpiryDateFormatter(), // Formato de MM/AA
                      ],
                      validator: (value) =>
                          value!.length < 5 ? 'Fecha inválida' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    // Campo de CVV
                    child: _buildPaymentTextField(
                      controller: _cvvController,
                      hintText: 'CVV',
                      icon: Icons.lock,
                      keyboardType: TextInputType.number,
                      isPassword: true,
                      maxLength: 3,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // Solo dígitos
                      ],
                      validator: (value) =>
                          value!.length < 3 ? 'CVV inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Resumen de la compra
              const Text(
                'Resumen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
                        'COMPLETAR COMPRA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
