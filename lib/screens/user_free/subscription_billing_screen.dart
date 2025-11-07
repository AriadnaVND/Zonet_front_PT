// lib/screens/user_free/subscription_billing_screen.dart
import 'package:flutter/material.dart';

class SubscriptionBillingScreen extends StatelessWidget {
  const SubscriptionBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Facturación'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFEEEEEE),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              const Text(
                'Sin Historial de Facturación',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryColor.withOpacity(0.5)),
                ),
                child: Text(
                  'Actualmente estás en el Plan Gratuito. '
                  'Las facturas y los detalles de pago aparecerán aquí '
                  'automáticamente una vez que te suscribas al Plan Premium.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
