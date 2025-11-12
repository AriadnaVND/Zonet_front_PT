import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../models/pet.dart';
import '../../services/community_service.dart';

class ReportLostPetModal extends StatefulWidget {
  final int userId;
  final Pet pet;
  final VoidCallback onReportSent;

  const ReportLostPetModal({
    super.key,
    required this.userId,
    required this.pet,
    required this.onReportSent,
  });

  @override
  State<ReportLostPetModal> createState() => _ReportLostPetModalState();
}

class _ReportLostPetModalState extends State<ReportLostPetModal> {
  final _formKey = GlobalKey<FormState>();
  final CommunityService _communityService = CommunityService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hoursLostController = TextEditingController();

  // Variables para la ubicación de Google Maps
  LatLng _lastSeenCoordinates = const LatLng(
    34.0522,
    -118.2437,
  ); // Default inicial
  String _lastSeenAddress = 'Selecciona una ubicación en el mapa.';
  bool _isGeocoding = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _hoursLostController.dispose();
    super.dispose();
  }

  // --- Geocodificación Inversa (De LatLng a Dirección) ---
  Future<void> _fetchAddressFromCoordinates(double lat, double lon) async {
    if (!mounted) return;
    setState(() {
      _isGeocoding = true;
      _lastSeenCoordinates = LatLng(lat, lon);
      _lastSeenAddress = 'Buscando dirección...';
    });

    try {
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
          _lastSeenAddress = address.isEmpty
              ? 'Dirección no encontrada'
              : address;
        });
      } else {
        setState(() {
          _lastSeenAddress =
              'Coordenadas: $lat, $lon (Dirección no encontrada)';
        });
      }
    } catch (_) {
      setState(() {
        _lastSeenAddress = 'Error de Geocodificación';
      });
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  // --- Enviar Reporte ---
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lastSeenAddress.contains('Selecciona') ||
        _lastSeenAddress.contains('Error')) {
      _showSnackbar(
        'Por favor, toca el mapa para indicar la última ubicación vista.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> lostPetData = {
      'petId': widget.pet.id,
      'description': _descriptionController.text.trim(),
      'hoursLost': int.tryParse(_hoursLostController.text.trim()) ?? 0,
      'lastSeenLocation': _lastSeenAddress,
      'lastSeenLatitude': _lastSeenCoordinates.latitude,
      'lastSeenLongitude': _lastSeenCoordinates.longitude,
    };

    try {
      await _communityService.reportLostPet(lostPetData);
      widget.onReportSent();
      if (mounted) Navigator.pop(context); // Cierra el modal al éxito
      _showSnackbar(
        '¡Alerta de ${widget.pet.name} enviada a la comunidad!',
        isError: false,
      );
    } catch (e) {
      _showSnackbar(
        'Fallo: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF00ADB5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFE57373); // Rojo de emergencia

    return Scaffold(
      appBar: AppBar(
        title: Text('Reportar ${widget.pet.name} Perdido'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '1. Última Ubicación Vista (Toca el mapa)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // --- Mapa de Selección de Ubicación ---
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _lastSeenCoordinates,
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      // Opcional: Obtener la ubicación real aquí si el paquete 'location' está disponible
                    },
                    onTap: (LatLng latLng) => _fetchAddressFromCoordinates(
                      latLng.latitude,
                      latLng.longitude,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('last_seen'),
                        position: _lastSeenCoordinates,
                        infoWindow: InfoWindow(
                          title: widget.pet.name,
                          snippet: _lastSeenAddress,
                        ),
                      ),
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),
              // Indicador de Dirección
              Row(
                children: [
                  Icon(Icons.location_on, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastSeenAddress,
                      style: TextStyle(
                        color: _isGeocoding ? Colors.grey : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_isGeocoding)
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const Divider(height: 30),

              const Text(
                '2. Detalles del Reporte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Campo Descripción
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText:
                      'Descripción (ej. Visto con collar rojo, asustado)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'La descripción es obligatoria' : null,
              ),
              const SizedBox(height: 15),

              // Campo Horas Perdido
              TextFormField(
                controller: _hoursLostController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Horas perdido (tiempo estimado)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: (value) =>
                    value!.isEmpty || int.tryParse(value) == null
                    ? 'Ingresa un número de horas válido'
                    : null,
              ),
              const SizedBox(height: 30),

              // Botón Final
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitReport,
                icon: Icon(Icons.warning_amber_rounded, color: Colors.white),
                label: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ACTIVAR ALERTA DE EMERGENCIA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
