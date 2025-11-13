// lib/screens/community_ai_matching_modal.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../models/ai_match_result.dart';
import '../../services/community_service.dart';

class CommunityAiMatchingModal extends StatefulWidget {
  final User user;
  final bool isPremium;

  const CommunityAiMatchingModal({
    super.key,
    required this.user,
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

  @override
  void initState() {
    super.initState();
    if (!widget.isPremium) {
      _errorMessage = "AI Matching es exclusivo para usuarios Premium.";
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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

      setState(() {
        _results = matches;
        if (matches.isEmpty) {
          _errorMessage =
              "No se encontraron coincidencias con un porcentaje mayor al 40%. Intenta con una imagen diferente.";
        }
      });
      _showSnackbar('Búsqueda completada.', isError: false);
    } catch (e) {
      String msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('Premium')) {
        _errorMessage =
            msg; // Muestra el mensaje de restricción de rol del backend
      } else {
        _errorMessage = 'Error en la búsqueda: $msg';
      }
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

  // --- Widgets Auxiliares ---
  Widget _buildResultCard(AiMatchResult result) {
    const Color primaryColor = Color(0xFF00ADB5);
    final String fullImageUrl = _communityService.buildFullImageUrl(
      result.imageUrl,
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coincidencia: ${result.matchPercentage}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: result.matchPercentage > 75
                        ? Colors.green.shade700
                        : primaryColor,
                  ),
                ),
                Text(
                  result.timeAgo,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        child: Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.petName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Última ubicación: ${result.locationName}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Razón de la IA: ${result.aiReasoning}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Selector de Imagen
            GestureDetector(
              onTap: widget.isPremium ? _pickImage : null,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: primaryColor.withOpacity(0.5)),
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
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // Botón de búsqueda (activado solo si hay imagen y es premium)
            ElevatedButton.icon(
              onPressed:
                  widget.isPremium && _selectedImage != null && !_isLoading
                  ? _runMatching
                  : null,
              icon: const Icon(Icons.search, color: Colors.white),
              label: Text(
                _isLoading ? 'BUSCANDO...' : 'BUSCAR COINCIDENCIAS CON IA',
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

            // 2. Resultados/Mensajes
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              )
            else if (_results != null && _results!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resultados Encontrados (Top 3):',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
