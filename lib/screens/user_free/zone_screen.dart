import 'package:flutter/material.dart';
// 💡 IMPORTACIÓN NECESARIA PARA MAPAS
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/user.dart';
import '../../models/pet.dart';
import '../../models/zone.dart';
import '../../services/zone_service.dart';
import '../plans/choose_plan_screen.dart';
import 'add_zone_screen.dart';

class ZoneScreen extends StatefulWidget {
  final User user;
  final Pet pet;

  const ZoneScreen({super.key, required this.user, required this.pet});

  @override
  State<ZoneScreen> createState() => _ZoneScreenState();
}

class _ZoneScreenState extends State<ZoneScreen> {
  final ZoneService _zoneService = ZoneService();

  // Base de datos de zonas (Contiene todas las zonas del usuario)
  List<Zone> _safeZones = [];
  bool _isLoading = true;
  final int _maxZones = 1; // Límite para el plan FREE

  // Variables del mapa
  GoogleMapController? _mapController;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  // ------------------------------------------
  // LÓGICA DE MAPA Y DATOS
  // ------------------------------------------

  // 💡 FUNCIÓN PRINCIPAL: Actualiza los marcadores y círculos del mapa
  void _updateMapElements() {
    _circles.clear();
    _markers.clear();

    // Posición por defecto si no hay zonas (se puede cambiar a la ubicación del usuario/mascota si está disponible)
    LatLng initialCenter = const LatLng(40.7128, -74.0060); // Ejemplo: NY

    if (_safeZones.isNotEmpty) {
      final firstZone = _safeZones.first;
      initialCenter = LatLng(firstZone.latitude, firstZone.longitude);

      for (var zone in _safeZones) {
        final LatLng center = LatLng(zone.latitude, zone.longitude);

        // 1. Agregar el círculo (la zona segura)
        _circles.add(
          Circle(
            circleId: CircleId(zone.id.toString()),
            center: center,
            radius: zone.radius.toDouble(),
            strokeWidth: 2,
            strokeColor: const Color(0xFF00ADB5),
            fillColor: const Color(0xFF00ADB5).withOpacity(0.15),
          ),
        );

        // 2. Agregar el marcador (el puntero)
        _markers.add(
          Marker(
            markerId: MarkerId(zone.id.toString()),
            position: center,
            infoWindow: InfoWindow(
              title: zone.name,
              snippet: 'Radio: ${zone.radius.toInt()}m',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }

      // Mover la cámara a la primera zona
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(initialCenter, 14),
      );
    }
  }

  Future<void> _fetchZones() async {
    setState(() => _isLoading = true);
    try {
      // Nota: El método en ZoneService es fetchSafeZones, lo mantengo así
      final zones = await _zoneService.fetchSafeZones(widget.user.id!);

      if (mounted) {
        setState(() {
          _safeZones = zones;
          _updateMapElements(); // 💡 ACTUALIZA MAPA
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackbar(
        'Error al cargar zonas: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteZone(int zoneId) async {
    try {
      await _zoneService.deleteSafeZone(zoneId);
      _showSnackbar('Zona eliminada correctamente.', isError: false);
      _fetchZones();
    } catch (e) {
      _showSnackbar(
        'Error al eliminar zona: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
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

  // ------------------------------------------
  // WIDGETS AUXILIARES REFACTORIZADOS
  // ------------------------------------------

  // 💡 NUEVO WIDGET: Reemplaza _buildPremiumCard (Muestra estado y permite mejorar)
  Widget _buildZoneStatusIndicator(bool isPremium, Color primaryColor) {
    final int zoneCount = _safeZones.length;
    final int maxZones = isPremium ? 999 : _maxZones;
    final String statusText;
    final Color statusColor;

    if (isPremium) {
      statusText = '$zoneCount Zonas Seguras Guardadas (PREMIUM)';
      statusColor = Colors.green.shade600;
    } else {
      if (zoneCount >= maxZones) {
        statusText = '$zoneCount Zona Segura Guardada (Límite FREE)';
        statusColor = Colors.red.shade700;
      } else {
        statusText = '$zoneCount/$maxZones Zonas Guardadas (FREE)';
        statusColor = Colors.orange.shade700;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.shield_outlined, color: statusColor, size: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Botón Mejorar si no es premium
          if (!isPremium)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChoosePlanScreen(
                      userId: widget.user.id!,
                      petName: widget.pet.name,
                      imageFile: null,
                      existingPhotoUrl: widget.pet.photoUrl,
                    ),
                  ),
                );
              },
              child: Text(
                'Mejorar',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 💡 NUEVO WIDGET: Contiene la lógica del mapa y los elementos cargados
  Widget _buildMap() {
    LatLng initialCenter = const LatLng(40.7128, -74.0060); // Default

    if (_safeZones.isNotEmpty) {
      final firstZone = _safeZones.first;
      initialCenter = LatLng(firstZone.latitude, firstZone.longitude);
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: GoogleMap(
            // La cámara inicial debe ser donde está el marcador de zona
            initialCameraPosition: CameraPosition(
              target: initialCenter,
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _updateMapElements();
            },
            markers: _markers, // Muestra los marcadores de las zonas
            circles: _circles, // Muestra los círculos de las zonas
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
          ),
        ),
      ),
    );
  }

  // 💡 WIDGET MODIFICADO: Encabezado y botón añadir zona
  Widget _buildAddZoneButton(Color primaryColor) {
    final isPremium = widget.user.plan?.toUpperCase() == 'PREMIUM';
    final bool canAddZone = isPremium || _safeZones.length < _maxZones;

    String buttonText = 'AÑADIR ZONA SEGURA';
    if (!isPremium) {
      if (!canAddZone) {
        buttonText = 'Límite alcanzado';
      } else {
        buttonText = 'AÑADIR ZONA SEGURA';
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Tus Zonas Seguras',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        // Botón Agregar Zona
        ElevatedButton.icon(
          onPressed: canAddZone
              ? () async {
                  // Asegurarse de refrescar la lista al volver
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddZoneScreen(
                        userId: widget.user.id!,
                        onZoneAdded: _fetchZones,
                      ),
                    ),
                  );
                  _fetchZones();
                }
              : null, // Deshabilitado si no puede agregar
          icon: const Icon(Icons.add, size: 20, color: Colors.white),
          label: Text(buttonText, style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: Size.zero,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // Widget para mostrar una zona guardada (se mantiene igual)
  Widget _buildZoneCard(Zone zone, Color primaryColor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.home, color: primaryColor, size: 30),
        title: Text(
          zone.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(zone.address, style: TextStyle(color: Colors.grey[600])),
            Text(
              'Radio: ${zone.radius.toInt()}m',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
              onPressed: () {
                // TODO: Implementar edición
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
              onPressed: () => _deleteZone(zone.id!),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);
    final isPremium = widget.user.plan?.toUpperCase() == 'PREMIUM';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonas Seguras'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.shield_outlined, color: Colors.grey),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFEEEEEE),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 💡 INDICADOR DE ESTADO (Reemplaza _buildPremiumCard)
                  _buildZoneStatusIndicator(isPremium, primaryColor),

                  const Text(
                    'Ubicación en el Mapa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 💡 MAPA CON MARCADORES/CÍRCULOS
                  _buildMap(),

                  const SizedBox(height: 20),

                  // ENCABEZADO Y BOTÓN AÑADIR ZONA
                  _buildAddZoneButton(primaryColor),

                  const SizedBox(height: 10),

                  // Lista de Zonas Guardadas
                  if (_safeZones.isEmpty)
                    const Center(
                      child: Text('Aún no tienes zonas seguras guardadas.'),
                    ),
                  ..._safeZones
                      .map((zone) => _buildZoneCard(zone, primaryColor))
                      .toList(),
                ],
              ),
            ),
    );
  }
}
