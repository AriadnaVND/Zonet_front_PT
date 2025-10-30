import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/pet.dart';
import '../../models/zone.dart';
import '../../services/zone_service.dart';
import '../plans/choose_plan_screen.dart'; // Para redirigir a planes
import 'add_zone_screen.dart'; // Para agregar una nueva zona

class ZoneScreen extends StatefulWidget {
  final User user;
  final Pet pet; // Necesario si quieres mostrar datos de la mascota o ubicación

  const ZoneScreen({super.key, required this.user, required this.pet});

  @override
  State<ZoneScreen> createState() => _ZoneScreenState();
}

class _ZoneScreenState extends State<ZoneScreen> {
  final ZoneService _zoneService = ZoneService();
  List<Zone> _safeZones = [];
  bool _isLoading = true;
  final int _maxZones = 1; // Para el plan FREE

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  Future<void> _fetchZones() async {
    try {
      final zones = await _zoneService.fetchSafeZones(widget.user.id!);
      setState(() {
        _safeZones = zones;
        _isLoading = false;
      });
    } catch (e) {
      _showSnackbar(
        'Error al cargar zonas: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteZone(int zoneId) async {
    try {
      await _zoneService.deleteSafeZone(zoneId);
      _showSnackbar('Zona eliminada correctamente.', isError: false);
      _fetchZones(); // Refresca la lista
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

  // --- Widgets Auxiliares ---

  // Tarjeta Plan Premium (Primera Pantalla)
  Widget _buildPremiumCard(Color primaryColor) {
    // 💡 Lógica del límite para plan FREE
    final currentZones = _safeZones.length;
    final maxZonesDisplay = widget.user.plan?.toUpperCase() == 'FREE'
        ? '1'
        : 'Ilimitadas';
    final progress = currentZones / _maxZones;
    final isMaxReached =
        currentZones >= _maxZones && widget.user.plan?.toUpperCase() == 'FREE';

    return GestureDetector(
      onTap: () {
        // Redirigir a la pantalla de planes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChoosePlanScreen(
              userId: widget.user.id!,
              petName: widget.pet.name!,
              imageFile: null,
              existingPhotoUrl: widget.pet.photoUrl,
            ),
          ),
        );
      },
      child: Card(
        color: isMaxReached
            ? Colors.red[50]
            : Colors.amber[50], // Fondo de advertencia si está lleno
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
          side: BorderSide(
            color: isMaxReached ? Colors.red : Colors.amber[700]!,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan Premium',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentZones/$maxZonesDisplay Zona${currentZones != 1 ? 's' : ''} Guardada${currentZones != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  // Barra de progreso visual
                  Container(
                    width: 150,
                    height: 8,
                    child: LinearProgressIndicator(
                      value: widget.user.plan?.toUpperCase() == 'FREE'
                          ? progress
                          : 0.0, // Solo muestra progreso en FREE
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isMaxReached ? Colors.red : primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              Icon(Icons.shield_outlined, color: primaryColor, size: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para mostrar una zona guardada
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
      backgroundColor: const Color(0xFFEEEEEE), // Fondo gris de la imagen
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPremiumCard(primaryColor),

                  // Ubicación Reciente (simulando ubicación del collar)
                  const Text(
                    'Ubicación Reciente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                      // TODO: Integrar un mapa (Google Maps/MapBox) aquí para la ubicación real.
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Encabezado de la lista de zonas y botón
                  Row(
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

                      // Botón Agregar Zona (Deshabilitado si se alcanzó el límite FREE)
                      ElevatedButton.icon(
                        onPressed: _safeZones.length < _maxZones
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddZoneScreen(
                                      userId: widget.user.id!,
                                      onZoneAdded:
                                          _fetchZones, // Callback para refrescar la lista
                                    ),
                                  ),
                                );
                              }
                            : null, // Deshabilitado
                        icon: const Icon(
                          Icons.add,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Agregar Zona',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize:
                              Size.zero, // Ajustar el tamaño al contenido
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
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
