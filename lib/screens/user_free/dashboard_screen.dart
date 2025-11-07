import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/pet.dart';
import '../../services/auth_service.dart';
import 'zone_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;
  final Pet pet;
  final int safeZoneCount; // 1 para Free, basado en SafeZoneService.java

  const DashboardScreen({
    super.key,
    required this.user,
    required this.pet,
    this.safeZoneCount = 1,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      // Navegar a la pantalla de Zonas Seguras
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ZoneScreen(
            user: widget.user,
            pet: widget.pet,
          ),
        ),
      );
    } else if (index == 2) {
      // Navegar a la pantalla de Comunidad
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(
            user: widget.user,
          ),
        ),
      );
    } else if (index == 3) {
      // Navegar a la pantalla de Ajustes
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsScreen(
            user: widget.user,
            pet: widget.pet,
          ),
        ),
      );
    }
  }

  Widget _buildHeader(Color primaryColor) {
    // 🟢 Construir la URL completa usando el método de AuthService
    final String fullImageUrl = _authService.buildFullImageUrl(
      widget.pet.photoUrl,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟢 DATOS DINÁMICOS: Nombre del usuario (jalado del registro/login)
              Text(
                'Hola, ${widget.user.name ?? 'Usuario'}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                // 🟢 DATOS DINÁMICOS: Plan del usuario
                child: Text(
                  widget.user.plan?.toUpperCase() ?? 'FREE',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.grey[700],
                  size: 28,
                ),
                onPressed: () {
                  /* Navegar a notificaciones */
                },
              ),
              const SizedBox(width: 8),
              // 🟢 DATOS DINÁMICOS: Foto de la mascota (usando NetworkImage y URL completa)
              CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(fullImageUrl),
                backgroundColor: Colors.grey[300],
                onBackgroundImageError: (exception, stackTrace) {
                  print('Error al cargar la imagen de la mascota: $exception');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widgets de contenido (Mapa y Tarjetas) ---
  Widget _buildMapSection(Color primaryColor) {
    // Implementación del mapa placeholder según la imagen
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ubicación Reciente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Placeholder del mapa con el marcador rojo
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey, width: 1.0),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(Color primaryColor, Color emergencyColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      child: Row(
        children: [
          // Card: Zonas Seguras
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ZoneScreen(
                      user: widget.user,
                      pet: widget.pet),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  border: Border.all(color: primaryColor, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, color: primaryColor, size: 45),
                    const SizedBox(height: 10),
                    const Text(
                      'Zonas seguras',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // 🟢 MUESTRA EL LÍMITE DEL PLAN FREE (1 zona)
                    Text(
                      '${widget.safeZoneCount} zona',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Card: Mascota Perdida (Emergencia)
          Expanded(
            child: GestureDetector(
              onTap: () {
                /* Llamar al endpoint /api/pets/lost */
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373), // Color de emergencia
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE57373).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 45,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Mascota perdida',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Emergencia',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);
    const Color accentColor = Color(0xFFEEEEEE);
    const Color emergencyColor = Color(0xFFE57373);

    return Scaffold(
      backgroundColor: accentColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(primaryColor),
              _buildMapSection(primaryColor),
              _buildActionCards(primaryColor, emergencyColor),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: 'Zonas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Comunidad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
