import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../services/zone_service.dart';

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
  bool _isLoading = false;

  // 💡 Datos simulados de la ubicación (requiere integración real de mapas/GPS)
  String _currentAddress = '2972 Westheimer Rd. Santa Ana, Illinois 85486';
  double _currentLat = 34.0522; // Ejemplo: Los Angeles
  double _currentLon = -118.2437;
  String? _selectedPreset = 'Casa';

  @override
  void dispose() {
    _nameController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveZone() async {
    if (!_formKey.currentState!.validate()) return;

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
                // Sección de Mapa (Ocupa la mitad superior de la pantalla)
                AspectRatio(
                  aspectRatio:
                      1 / 1, // Mapa cuadrado para un mejor uso del espacio
                  child: Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Placeholder del Mapa
                        Image.asset(
                          'assets/images/map_placeholder.png', // Usar una imagen o un Container gris
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),

                        // Marcador de Ubicación
                        Icon(Icons.location_pin, color: Colors.red, size: 40),
                        // Círculo de Radio (Simulación)
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.2),
                            border: Border.all(color: primaryColor, width: 2),
                          ),
                        ),
                      ],
                    ),
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
                          'Tu ubicación',
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
                            IconButton(
                              icon: const Icon(
                                Icons.search,
                                color: primaryColor,
                              ),
                              onPressed: () {
                                /* TODO: Abrir buscador de dirección */
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.gps_fixed,
                                color: primaryColor,
                              ),
                              onPressed: () {
                                /* TODO: Usar GPS del celular */
                              },
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
