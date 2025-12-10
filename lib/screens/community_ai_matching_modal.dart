// lib/screens/community_ai_matching_modal.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../models/pet.dart';
import '../../models/ai_match_result.dart';
import '../../services/community_service.dart';

class CommunityAiMatchingModal extends StatefulWidget {
  final User user;
  final Pet? pet;
  final bool isPremium;

  const CommunityAiMatchingModal({
    super.key,
    required this.user,
    required this.pet,
    required this.isPremium,
  });

  @override
  State<CommunityAiMatchingModal> createState() =>
      _CommunityAiMatchingModalState();
}

class _CommunityAiMatchingModalState extends State<CommunityAiMatchingModal> {
  final CommunityService _communityService = CommunityService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;
  List<AiMatchResult>? _results;
  String? _errorMessage;

  // 1. PASOS DE ANÁLISIS (Para la nueva pantalla de carga visual)
  final List<String> _analysisSteps = [
    'Subiendo y procesando imagen en el servidor...',
    'Inicializando motor de Gemini AI...',
    'Análisis de patrones de pelaje y color.',
    'Identificación de forma facial y cuerpo.',
    'Comparación con base de datos de mascotas perdidas Zoonet.',
    'Calculando porcentaje de coincidencia...',
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.isPremium) {
      _errorMessage = "AI Matching es exclusivo para usuarios Premium.";
    } else if (widget.user.id == null) {
      _errorMessage =
          "Error de sesión: El usuario no tiene un ID válido. Por favor, reinicie la aplicación.";
    } else if (widget.pet == null || widget.pet!.id <= 0) {
      _errorMessage =
          "Error de datos: La mascota del usuario no tiene un ID válido o no fue cargada correctamente.";
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(
            pickedFile.path,
          ); // El File se crea correctamente
          _results = null;
          _errorMessage = null;
        });
        _showSnackbar('Imagen seleccionada correctamente.', isError: false);
      }
    } catch (e) {
      // 💡 IMPORTANTE: Manejo de errores para permisos de la galería
      String errorMessage =
          'Fallo al seleccionar la imagen. Verifica los permisos de la galería.';
      if (e.toString().contains('PlatformException')) {
        errorMessage =
            'Error de permiso: Asegúrate de que la aplicación tiene acceso a tus fotos.';
      }
      _showSnackbar(errorMessage, isError: true);
      setState(() {
        _errorMessage = errorMessage;
      });
    }
  }

  Future<void> _runMatching() async {
    if (_selectedImage == null) {
      _showSnackbar(
        'Por favor, selecciona una foto de la mascota a buscar.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final matches = await _communityService.findAiMatches(
        widget.user.id!,
        _selectedImage!,
      );

      if (mounted) {
        setState(() {
          _results = matches;
          if (matches.isEmpty) {
            _errorMessage =
                "No se encontraron coincidencias con un porcentaje mayor al 40%. Intenta con una imagen diferente.";
          }
        });
      }
      _showSnackbar('Búsqueda completada.', isError: false);
    } catch (e) {
      String msg = e.toString().replaceFirst('Exception: ', '');

      // Construir el mensaje de error final
      String finalErrorMsg;
      if (msg.contains('NotFound') ||
          msg.contains('Usuario no encontrado') ||
          msg.contains('Mascota no encontrada')) {
        finalErrorMsg =
            'Error de datos: Usuario o mascota no encontrados en el servidor. Por favor, verifique su sesión e intente nuevamente.';
      } else if (msg.contains('Acceso denegado')) {
        finalErrorMsg = msg;
      } else {
        finalErrorMsg = 'Error en la búsqueda: $msg';
      }

      // 💡 CORRECCIÓN 2: Actualizar _errorMessage en el estado SÓLO si está montado
      if (mounted) {
        setState(() {
          _errorMessage = finalErrorMsg;
          // Note: _isLoading se manejará en el bloque finally
        });
      }
    } finally {
      // 💡 CORRECCIÓN 3: Asegurar que _isLoading se desactive siempre (si está montado)
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

  // --- Widgets Auxiliares ---
  // 2. WIDGET PARA LA PANTALLA DE ANÁLISIS (Reemplaza el CircularProgressIndicator)
  Widget _buildAnalysisScreen(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen de la mascota subida (diseño central)
            if (_selectedImage != null)
              ClipOval(
                child: Image.file(
                  _selectedImage!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 30),

            // Texto de Análisis Principal
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_outlined,
                  color: primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'Analizando con Zoonet AI...',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Barra de Progreso Indeterminada (más visual)
            LinearProgressIndicator(
              color: primaryColor,
              backgroundColor: primaryColor.withOpacity(0.2),
            ),
            const SizedBox(height: 20),

            // Lista de Pasos de Verificación (simulando actividad)
            SizedBox(
              height: 180, // Limita la altura para no ocupar toda la pantalla
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: _analysisSteps
                    .map(
                      (step) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: primaryColor.withOpacity(0.7),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(AiMatchResult result) {
    const Color primaryColor = Color(0xFF00ADB5);
    final String fullImageUrl = _communityService.buildFullImageUrl(
      result.imageUrl,
    );

    // Color para la barra de progreso
    Color matchColor;
    if (result.matchPercentage >= 80) {
      matchColor = Colors.green.shade700;
    } else if (result.matchPercentage >= 50) {
      matchColor = Colors.orange.shade700;
    } else {
      matchColor = primaryColor;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detalles de la Mascota
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la Mascota
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    fullImageUrl,
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),

                // Detalles y Porcentaje
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.petName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        result.description,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      // Ubicación y Tiempo
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              result.locationName,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.timeAgo,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 25),

            // Indicador de Progreso de Coincidencia
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nivel de Coincidencia',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${result.matchPercentage}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: matchColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: result.matchPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  color: matchColor,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Razón IA: ${result.aiReasoning}',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
        title: const Text('AI Matching'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading &&
              _selectedImage !=
                  null // Nueva lógica de control de estado
          ? _buildAnalysisScreen(
              context,
            ) // Muestra la pantalla de análisis (Diseño de carga)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Selector de Imagen (sin cambios)
                  GestureDetector(
                    onTap: widget.isPremium ? _pickImage : null,
                    child: ConstrainedBox(
                      // <--- USAMOS CONSTRAINED BOX
                      constraints: const BoxConstraints(
                        maxHeight:
                            300, // Define una altura máxima razonable (ej: 250px)
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.5),
                          ),
                        ),
                        child: _selectedImage == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_library,
                                      size: 40,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Selecciona una imagen de la galería para buscar coincidencias.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botón de búsqueda (sin cambios)
                  ElevatedButton.icon(
                    onPressed:
                        widget.isPremium &&
                            _selectedImage != null &&
                            !_isLoading
                        ? _runMatching
                        : null,
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: Text(
                      _isLoading
                          ? 'BUSCANDO...'
                          : 'BUSCAR COINCIDENCIAS CON IA',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Resultados/Mensajes (Se removió el antiguo CircularProgressIndicator)
                  if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else if (_results != null && _results!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resultados Encontrados (Top 3):',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        ..._results!.map(_buildResultCard).toList(),
                      ],
                    )
                  else if (_selectedImage != null &&
                      _results != null &&
                      _results!.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text(
                          "No se encontraron coincidencias. Intenta con otra foto.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
