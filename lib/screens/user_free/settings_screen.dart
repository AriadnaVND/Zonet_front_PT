// lib/screens/user_free/settings_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/pet.dart';
import '../../services/auth_service.dart';
import '../plans/choose_plan_screen.dart';
import 'profile_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'subscription_screen.dart';

class SettingsScreen extends StatelessWidget {
  final User user;
  final Pet pet; // Se necesita la mascota para mostrar la foto y el plan

  const SettingsScreen({super.key, required this.user, required this.pet});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);
    final AuthService authService = AuthService();

    // 🟢 Construir la URL completa para la foto de la mascota
    final String fullImageUrl = authService.buildFullImageUrl(pet.photoUrl);

    // El plan del usuario Free es fijo
    final String userPlan = user.plan?.toUpperCase() ?? 'FREE';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
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
      backgroundColor: const Color(0xFFEEEEEE), // Fondo gris del diseño
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Tarjeta de Perfil y Plan
            _buildProfileCard(
              context,
              fullImageUrl,
              user.name ?? 'Usuario',
              user.email ?? 'email@example.com',
              userPlan,
              primaryColor,
            ),
            const SizedBox(height: 20),

            // 2. Opciones de Navegación
            _buildSettingsList(context, primaryColor),

            const SizedBox(height: 30),

            // 3. Footer / Copyright
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

  // --- Widgets Auxiliares ---

  Widget _buildProfileCard(
    BuildContext context,
    String imageUrl,
    String name,
    String email,
    String plan,
    Color primaryColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: NetworkImage(imageUrl),
              backgroundColor: Colors.grey[300],
              onBackgroundImageError: (exception, stackTrace) {
                // Manejo de error si la imagen falla
                print('Error loading image: $exception');
              },
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: plan == 'PREMIUM'
                        ? const Color(0xFFE57373)
                        : primaryColor, // Rojo si es Premium, Turquesa si es FREE
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        _buildSettingTile(
          icon: Icons.person_outline,
          title: 'Configuración De Perfil',
          subtitle: 'Administra La Información De Tu Cuenta',
          onTap: () {
            // 🟢 NAVEGACIÓN A CONFIGURACIÓN DE PERFIL
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfileSettingsScreen(user: user, pet: pet),
              ),
            );
          },
        ),
        _buildSettingTile(
          icon: Icons.notifications_none_outlined,
          title: 'Notificaciones',
          subtitle: 'Preferencias Y Configuración De Alertas',
          onTap: () {
            // 🟢 NAVEGACIÓN A CONFIGURACIÓN DE NOTIFICACIONES
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            );
          },
        ),
        _buildSettingTile(
          icon: Icons.payment_outlined,
          title: 'Suscripción',
          subtitle: 'Administra Tu Plan Y Facturación',
          onTap: () {
            // 🟢 NAVEGACIÓN A PANTALLA DE MENÚ DE SUSCRIPCIONES
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubscriptionScreen(user: user),
              ),
            );
          },
        ),
        _buildSettingTile(
          icon: Icons.help_outline,
          title: 'Ayuda Y Soporte',
          subtitle: 'Obtén Ayuda Y Contacta Con El Soporte Técnico',
          onTap: () {
            // TODO: Implementar navegación a Ayuda/Soporte
          },
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87, size: 30),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
