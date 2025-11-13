import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/pet.dart';
import '../../models/location.dart';
import '../../services/auth_service.dart';
import '../../services/tracker_service.dart';
import '../user_free/zone_screen.dart'; // Reutilizar la pantalla de zonas
import '../user_free/community_screen.dart'; // Reutilizar la pantalla de comunidad
import '../user_free/settings_screen.dart'; // Reutilizar la pantalla de ajustes
import '../user_free/notification_list_screen.dart'; // Reutilizar la lista de notificaciones
// 💡 NUEVA PANTALLA: Historial de Rutas
import 'tracking_history_screen.dart';
import '../user_free/report_lost_pet_modal.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class PremiumHomeScreen extends StatefulWidget {
  final User user;
  final Pet pet;
  // El plan Premium implica zonas ilimitadas (simularemos un alto número)
  final int safeZoneCount;

  const PremiumHomeScreen({
    super.key,
    required this.user,
    required this.pet,
    this.safeZoneCount = 999, // Simula ilimitadas
  });

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final TrackerService _trackerService = TrackerService();

  PetLocation? _currentPetLocation;
  bool _isLocationLoading = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _fetchPetLocation();
    // 💡 Para simular el rastreo en tiempo real, puedes iniciar un timer aquí
    // Timer.periodic(Duration(seconds: 10), (Timer t) => _fetchPetLocation());
  }

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

  // 🟢 NUEVO MÉTODO: Mostrar el modal de reporte
  void _showReportModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ReportLostPetModal(
            userId: widget.user.id!,
            pet: widget.pet,
            // Al enviar el reporte con éxito, refrescamos el estado del mapa
            onReportSent: _fetchPetLocation,
          ),
        );
      },
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ZoneScreen(user: widget.user, pet: widget.pet),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CommunityScreen(user: widget.user, pet: widget.pet),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SettingsScreen(user: widget.user, pet: widget.pet),
        ),
      );
    }
  }

  // --- Header y Notificaciones (Reutilizado de DashboardScreen) ---
  Widget _buildHeader(Color primaryColor) {
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
                  // 💡 CAMBIO: Usar un color diferente para destacar PREMIUM
                  color: Colors.amber[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.user.plan?.toUpperCase() ?? 'PREMIUM',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_active_outlined, // 💡 Icono más activo
                  color: Colors.amber[700],
                  size: 28,
                ),
                onPressed: () {
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
              CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(fullImageUrl),
                backgroundColor: Colors.grey[300],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Sección de Mapa (Rastreo en Tiempo Real) ---
  Widget _buildMapSection(Color primaryColor) {
    Widget mapContent;
    String statusText;
    Color statusColor;
    LatLng mapCenter;
    Set<Marker> markers = {};
    String lastUpdate = '';

    if (_isLocationLoading) {
      mapCenter = const LatLng(34.0522, -118.2437);
      statusText = 'Rastreo Activo...';
      statusColor = Colors.green; // Siempre verde para Premium
      mapContent = const Center(child: CircularProgressIndicator());
    } else if (_locationError != null || _currentPetLocation == null) {
      mapCenter = const LatLng(34.0522, -118.2437);
      statusText = 'Sin Señal';
      statusColor = Colors.red;
      mapContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _locationError ??
                'Ubicación no reportada. Comprueba el dispositivo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      );
    } else {
      // Datos de ubicación de tiempo real (asumiendo que el backend envía datos más recientes)
      mapCenter = LatLng(
        _currentPetLocation!.latitude,
        _currentPetLocation!.longitude,
      );
      statusText = 'En Tiempo Real';
      statusColor = Colors.green;
      lastUpdate = timeago.format(_currentPetLocation!.timestamp, locale: 'es');

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
      );
    }

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
                'Ubicación En Tiempo Real', // 💡 CAMBIO DE TEXTO
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
          if (lastUpdate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Actualizado $lastUpdate',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 15),
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

  // --- Tarjetas de Acción (Incluye Historial de Rutas) ---
  Widget _buildActionCards(Color primaryColor, Color emergencyColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      child: Column(
        children: [
          Row(
            children: [
              // Card: Zonas Seguras
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Reutilizar la pantalla de zonas (ahora con límite alto)
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
                        Icon(
                          Icons.shield_outlined,
                          color: primaryColor,
                          size: 45,
                        ),
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
                        const Text(
                          'Ilimitadas', // 💡 CAMBIO DE TEXTO
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF00ADB5),
                          ),
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
                  // 🟢 LLAMADA AL MODAL DE REPORTE
                  onTap: _showReportModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: emergencyColor,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: emergencyColor.withOpacity(0.3),
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
                          'Alerta a toda la comunidad', // 💡 CAMBIO DE TEXTO
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
          const SizedBox(height: 16),

          // Card: Historial de Rutas (Beneficio Premium)
          GestureDetector(
            onTap: () {
              // 🟢 NAVEGAR AL HISTORIAL DE RUTAS
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TrackingHistoryScreen(user: widget.user, pet: widget.pet),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(
                  color: primaryColor.withOpacity(0.6),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: primaryColor, size: 30),
                  const SizedBox(width: 15),
                  const Text(
                    'Historial de Rutas', // 💡 CAMBIO DE TEXTO
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
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
