// lib/screens/user_free/subscription_plan_details_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../plans/choose_plan_screen.dart';

class SubscriptionPlanDetailsScreen extends StatelessWidget {
  final User user;

  const SubscriptionPlanDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);
    final isFree = user.plan?.toUpperCase() == 'FREE';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isFree ? 'Detalles del Plan FREE' : 'Detalles del Plan PREMIUM',
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de Plan Actual
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isFree
                    ? primaryColor.withOpacity(0.1)
                    : Colors.amber.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isFree ? primaryColor : Colors.amber.shade700,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'PLAN ACTUAL',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  Text(
                    user.plan?.toUpperCase() ?? 'FREE',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isFree ? primaryColor : Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Título de Beneficios
            const Text(
              'Beneficios Incluidos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            // Lista de Beneficios (Mapeo de Plan)
            _buildFeatureRow(
              'Seguimiento Básico (Ubicación cada 30 min)',
              isFree ? primaryColor : Colors.green,
            ),
            _buildFeatureRow(
              '1 Zona Segura',
              isFree ? primaryColor : Colors.green,
            ),
            _buildFeatureRow(
              'Límite de 3 Reportes de Pérdida Activos',
              isFree ? primaryColor : Colors.green,
            ),
            _buildFeatureRow(
              'Acceso Limitado a Comunidad',
              isFree ? primaryColor : Colors.green,
            ),

            const SizedBox(height: 30),

            // Sección de Upgrade (Solo si es Free)
            if (isFree) ...[
              const Text(
                'Desbloquea Funcionalidades:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildFeatureRow('Seguimiento en Tiempo Real', Colors.red),
              _buildFeatureRow('Zonas Seguras Ilimitadas', Colors.red),
              _buildFeatureRow('Alertas de Vía/SMS (Premium)', Colors.red),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  // Redirigir a la pantalla de planes
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChoosePlanScreen(
                        userId: user.id!,
                        petName: user.name ?? '',
                        imageFile: null,
                        existingPhotoUrl: '',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'MEJORA TU PLAN A PREMIUM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
