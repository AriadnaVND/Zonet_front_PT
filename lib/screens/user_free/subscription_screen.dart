// lib/screens/user_free/subscription_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../plans/choose_plan_screen.dart'; // Para "Ver Planes Disponibles"
import 'subscription_plan_details_screen.dart'; // Nuevo: Detalles del Plan
import 'subscription_billing_screen.dart'; // Nuevo: Detalles de Facturación

class SubscriptionScreen extends StatelessWidget {
  final User user;

  const SubscriptionScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final String userPlan = user.plan?.toUpperCase() ?? 'FREE';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Suscripciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFEEEEEE),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Datos de la Cuenta
            _buildInfoCard(
              title: 'Datos De La Cuenta',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nombre De Usuario',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    user.name ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Email',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    user.email ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. Tu Plan (Navegación a detalles o upgrade)
            _buildActionTile(
              icon: Icons.person_outline,
              title: 'Tu Plan',
              subtitle: userPlan == 'FREE'
                  ? 'Free - Mejora Tu Plan'
                  : 'Premium',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SubscriptionPlanDetailsScreen(user: user),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // 3. Facturación (Navegación a detalles de facturación/historial)
            _buildActionTile(
              icon: Icons.notifications_none_outlined,
              title: 'Facturación',
              subtitle: 'Ver Detalles',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionBillingScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // 4. Ver Planes Disponibles (Navegación directa a la pantalla de compra)
            _buildActionTile(
              icon: Icons.credit_card_outlined,
              title: 'Ver Planes Disponibles',
              subtitle: '', // El diseño de la imagen no tiene subtítulo aquí
              showIcon: false, // Quita el icono de inicio
              trailingIcon: Icons.arrow_forward_ios,
              onTap: () {
                // Navegación a la pantalla de selección de planes
                // Nota: Los datos de mascota (petName, imageFile) ya no son necesarios
                // porque el usuario ya está registrado. Solo necesitamos el userId.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChoosePlanScreen(
                      userId: user.id!,
                      petName: user.name ?? '', // Placeholder de nombre
                      imageFile: null,
                      existingPhotoUrl: '', // No es relevante en este flujo
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'Zoonet\n© ${DateTime.now().year} Zoonet Inc.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Widget para el primer Card (Datos de la Cuenta)
  Widget _buildInfoCard({required String title, required Widget content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  // Widget para las opciones de menú (Tu Plan, Facturación, Ver Planes)
  Widget _buildActionTile({

    required IconData? icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    IconData? trailingIcon = Icons.arrow_forward_ios,
    bool showIcon = true,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: showIcon ? Icon(icon, color: Colors.black87, size: 30) : null,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              )
            : null,
        trailing: trailingIcon != null
            ? Icon(trailingIcon, size: 18, color: Colors.grey)
            : null,
        onTap: onTap,
      ),
    );
  }
}
