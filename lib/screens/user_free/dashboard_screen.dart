import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/pet.dart';
import '../../models/location.dart';
import '../../services/auth_service.dart';
import '../../services/tracker_service.dart';
import 'zone_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';
import 'notification_list_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  final TrackerService _trackerService = TrackerService();

  PetLocation? _currentPetLocation;
  bool _isLocationLoading = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages(
      'es',
      timeago.EsMessages(),
    ); // Asegurar que timeago esté en español
    _fetchPetLocation();
  }

  // NUEVO MÉTODO: Obtener la ubicación de la mascota del backend
  Future<void> _fetchPetLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
    });

    try {
      final location = await _trackerService.fetchCurrentLocation(
        widget.pet.id,
      );
      setState(() {
        _currentPetLocation = location;
      });
    } catch (e) {
      // Si el backend devuelve "No se encontró ubicación para la mascota.",
      // se muestra el error de forma amigable.
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _locationError = errorMessage.contains('No se encontró')
            ? 'La ubicación del dispositivo aún no ha sido reportada.'
            : 'Error al conectar: $errorMessage';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      // Navegar a la pantalla de Zonas Seguras
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ZoneScreen(user: widget.user, pet: widget.pet),
        ),
      );
    } else if (index == 2) {
      // Navegar a la pantalla de Comunidad
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityScreen(user: widget.user),
        ),
      );
    } else if (index == 3) {
      // Navegar a la pantalla de Ajustes
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SettingsScreen(user: widget.user, pet: widget.pet),
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
                  // NAVEGAR A LA PANTALLA DE LISTA DE ALERTAS
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationListScreen(
                        user: widget.user,
                        pet: widget.pet,
                      ),
                    ),
                  );
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
    // Lógica para mostrar el estado de la ubicación
    Widget mapContent;
    String statusText;
    Color statusColor;
    LatLng mapCenter;
    Set<Marker> markers = {};
    String lastUpdate = '';

    if (_isLocationLoading) {
      mapCenter = const LatLng(34.0522, -118.2437); // Default
      statusText = 'Cargando Ubicación...';
      statusColor = Colors.grey;
      mapContent = const Center(child: CircularProgressIndicator());
    } else if (_locationError != null || _currentPetLocation == null) {
      // Muestra error si no hay datos o la conexión falló
      mapCenter = const LatLng(34.0522, -118.2437); // Default
      statusText = 'Desconectado';
      statusColor = Colors.red;
      mapContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _locationError ??
                'La ubicación del dispositivo aún no ha sido reportada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      );
    } else {
      // Datos de ubicación recibidos y listos para el mapa
      mapCenter = LatLng(
        _currentPetLocation!.latitude,
        _currentPetLocation!.longitude,
      );
      statusText = 'Online';
      statusColor = Colors.green;
      lastUpdate = timeago.format(_currentPetLocation!.timestamp, locale: 'es');

      // Crea el marcador de la mascota
      markers.add(
        Marker(
          markerId: const MarkerId('pet_tracker_location'),
          position: mapCenter,
          infoWindow: InfoWindow(
            title: widget.pet.name,
            snippet: 'Actualizado: $lastUpdate',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );

      // Muestra el mapa con el marcador
      mapContent = GoogleMap(
        initialCameraPosition: CameraPosition(target: mapCenter, zoom: 16),
        markers: markers,
        zoomControlsEnabled: true,
        myLocationButtonEnabled: false,
        // Al tocar el mapa, centra la cámara en la ubicación de la mascota
        onTap: (_) {
          // Opcional: Animar la cámara de nuevo a la posición de la mascota
          // if (mapController != null) {
          //   mapController!.animateCamera(CameraUpdate.newLatLng(mapCenter));
          // }
        },
      );
    }

    // Implementación del mapa placeholder
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
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Muestra la hora de la última actualización si está online
          if (lastUpdate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Actualizado $lastUpdate',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),

          const SizedBox(height: 15),

          // Área del Mapa/Contenido
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: mapContent,
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
                    builder: (context) =>
                        ZoneScreen(user: widget.user, pet: widget.pet),
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
        child: RefreshIndicator(
          onRefresh: _fetchPetLocation,
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
