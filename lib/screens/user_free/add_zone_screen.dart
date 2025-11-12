import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../services/zone_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:location/location.dart';

class AddZoneScreen extends StatefulWidget {
  final int userId;
  final VoidCallback onZoneAdded; // Callback para refrescar la lista

  const AddZoneScreen({
    super.key,
    required this.userId,
    required this.onZoneAdded,
  });

  @override
  State<AddZoneScreen> createState() => _AddZoneScreenState();
}

class _AddZoneScreenState extends State<AddZoneScreen> {
  final ZoneService _zoneService = ZoneService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(
    text: '500',
  ); // Valor por defecto
  final _formKey = GlobalKey<FormState>();

  GoogleMapController? _mapController;
  Location _locationService = Location();

  bool _isLoading = false;

  // 💡 Datos simulados de la ubicación (requiere integración real de mapas/GPS)
  String _currentAddress = 'Ubicacion no disponible';
  double _currentLat = 34.0522; // Ejemplo: Los Angeles
  double _currentLon = -118.2437;
  String? _selectedPreset = 'Casa';

  final LatLng _initialCameraPosition = const LatLng(34.0522, -118.2437);

  @override
  void initState() {
    super.initState();
    // Obtener la ubicación actual al iniciar
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _nameController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  // --- Lógica de Servicios de Ubicación (GPS y Geocodificación) ---

  // 1. Obtener ubicación actual (para centrar el mapa y usar el GPS)
  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _locationService.getLocation();

      if (locationData.latitude != null && locationData.longitude != null) {
        // 💡 CORRECCIÓN: Usar _mapController solo si no es nulo
        if (_mapController != null) {
          _mapController!.animateCamera(
            // Usar el operador ! para indicar que no es nulo después de la comprobación
            CameraUpdate.newLatLng(
              LatLng(locationData.latitude!, locationData.longitude!),
            ),
          );
        }
        // Establecer el marcador inicial en la ubicación del usuario
        await _fetchAddressFromCoordinates(
          locationData.latitude!,
          locationData.longitude!,
        );
      }
    } catch (e) {
      _showSnackbar('Fallo al obtener la ubicación GPS: $e', isError: true);
      // Si falla, el mapa permanecerá en la posición inicial (_initialCameraPosition)
    }
  }

  // 2. Obtener dirección legible a partir de coordenadas (Geocodificación inversa)
  Future<void> _fetchAddressFromCoordinates(double lat, double lon) async {
    setState(() {
      _currentAddress = 'Buscando dirección...';
      _currentLat = lat;
      _currentLon = lon;
    });

    try {
      // Usando el paquete geocoding para obtener la dirección real
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(lat, lon);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _currentAddress = address.isEmpty
              ? 'Dirección no encontrada'
              : address;
        });
      } else {
        setState(() {
          _currentAddress = 'Coordenadas: $lat, $lon';
        });
      }
    } catch (e) {
      _showSnackbar('Error al obtener la dirección: $e', isError: true);
      setState(() {
        _currentAddress = 'Error de Geocodificación';
      });
    }
  }

  // --- Lógica de Guardar Zona ---

  Future<void> _handleSaveZone() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentAddress == 'Ubicación no seleccionada' ||
        _currentAddress.startsWith('Error')) {
      _showSnackbar(
        'Por favor, selecciona una ubicación válida en el mapa.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newZone = Zone(
      userId: widget.userId,
      name: _nameController.text.isEmpty
          ? (_selectedPreset ?? 'Zona Segura')
          : _nameController.text,
      latitude: _currentLat,
      longitude: _currentLon,
      radius: double.tryParse(_radiusController.text) ?? 500.0,
      address: _currentAddress,
    );

    try {
      await _zoneService.createSafeZone(newZone);
      widget.onZoneAdded(); // Llama al callback para refrescar la lista
      _showSnackbar('Zona segura guardada correctamente.');
      if (mounted) Navigator.pop(context); // Regresar a la pantalla de listado
    } catch (e) {
      _showSnackbar(
        'Error: ${e.toString().replaceFirst('Exception: ', '')}',
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

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);
    final initialPosition = LatLng(_currentLat, _currentLon);

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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 150,
            ), // Espacio para el botón fijo
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sección de Mapa (Reemplaza el Placeholder por el Mapa Real)
                AspectRatio(
                  aspectRatio: 1 / 1,
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _initialCameraPosition,
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // Si ya se obtuvo la ubicación actual al iniciar, se centra.
                      if (_currentLat != _initialCameraPosition.latitude ||
                          _currentLon != _initialCameraPosition.longitude) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(initialPosition),
                        );
                      }
                    },
                    // Captura el toque en el mapa para definir la zona
                    onTap: (LatLng latLng) {
                      _fetchAddressFromCoordinates(
                        latLng.latitude,
                        latLng.longitude,
                      );
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('zone_location'),
                        position: LatLng(_currentLat, _currentLon),
                        infoWindow: InfoWindow(
                          title: _nameController.text.isNotEmpty
                              ? _nameController.text
                              : 'Nueva Zona',
                        ),
                      ),
                    },
                    circles: {
                      Circle(
                        circleId: const CircleId('safe_zone_radius'),
                        center: LatLng(_currentLat, _currentLon),
                        radius:
                            double.tryParse(_radiusController.text) ?? 500.0,
                        fillColor: primaryColor.withOpacity(0.2),
                        strokeColor: primaryColor,
                        strokeWidth: 2,
                      ),
                    },
                  ),
                ),

                // Contenido del Formulario
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seleccionar ubicación',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Campo "Tu ubicación"
                        Text(
                          'Ubicación seleccionada',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _currentAddress,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Botones de acción (Simulación de búsqueda/GPS)
                            // El botón de GPS ahora usa el servicio `location`
                            IconButton(
                              icon: const Icon(
                                Icons.gps_fixed,
                                color: primaryColor,
                              ),
                              onPressed: _getCurrentLocation,
                            ),
                          ],
                        ),
                        const Divider(),

                        // Campo "Guardar como"
                        Text(
                          'Guardar como',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),

                        // Presets de Zonas
                        Wrap(
                          spacing: 8.0,
                          children: ['Casa', 'Parque', 'Trabajo'].map((label) {
                            final isSelected = _selectedPreset == label;
                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              selectedColor: primaryColor.withOpacity(0.2),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedPreset = selected ? label : null;
                                  _nameController.text = isSelected
                                      ? ''
                                      : label;
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 15),

                        // Input para nombre personalizado (opcional)
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre de Zona (opcional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.label_outline),
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value.isNotEmpty) {
                                _selectedPreset = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 15),

                        // Input para Radio (solo un placeholder visual, no se usa el valor en el DTO/backend)
                        TextFormField(
                          controller: _radiusController,
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value!.isEmpty || double.tryParse(value) == null
                              ? 'Radio inválido'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Radio de la zona (en metros)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.circle_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón fijo en la parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSaveZone,
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
                        'GUARDAR DIRECCIÓN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
