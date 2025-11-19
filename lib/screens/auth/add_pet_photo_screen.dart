import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../plans/choose_plan_screen.dart';

class AddPetPhotoScreen extends StatefulWidget {
  final int userId;
  final String userName; // Nombre del usuario

  const AddPetPhotoScreen({
    super.key,
    required this.userId,
    required this.userName, // El nombre del usuario ahora es requerido
  });

  @override
  State<AddPetPhotoScreen> createState() => _AddPetPhotoScreenState();
}

class _AddPetPhotoScreenState extends State<AddPetPhotoScreen> {
  final TextEditingController _petNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _petNameController.dispose();
    super.dispose();
  }

  // --- Lógica para seleccionar la imagen ---
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Lógica para navegar a la siguiente pantalla (Elegir Plan)
  void _navigateToChoosePlan() {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar(
        'Por favor, ingresa el nombre de tu mascota.',
        isError: true,
      );
      return;
    }
    if (_imageFile == null) {
      _showSnackbar('Debes subir una foto de tu mascota.', isError: true);
      return;
    }

    // Navega a la pantalla de planes, pasando la información necesaria para el siguiente paso (el registro final)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChoosePlanScreen(
          userId: widget.userId,
          petName: _petNameController.text,
          imageFile: _imageFile!,
        ),
      ),
    );
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

  // --- Diseño de la Interfaz de Usuario ---
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);
    final isPhotoSelected = _imageFile != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Título
              const Text(
                'Añade la foto de tu mascota',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              const Text(
                'Ayúdanos a mantener\nSeguro a tu amigo/a peludo',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Contenedor de la foto (Círculo Turquesa)
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 4),
                    ),
                    child: ClipOval(
                      child: _imageFile == null
                          ? const Center(
                              child: Icon(
                                Icons.camera_alt,
                                size: 60,
                                color: primaryColor,
                              ),
                            )
                          : Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Campo para el Nombre de la Mascota
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: TextFormField(
                  controller: _petNameController,
                  validator: (value) =>
                      value!.isEmpty ? 'Ingresa el nombre de tu mascota' : null,
                  decoration: InputDecoration(
                    hintText: 'Nombre de la mascota',
                    icon: Icon(Icons.pets, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón TOMAR FOTO (Primario)
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  'TOMAR FOTO',
                  style: TextStyle(
                    fontSize: 18,
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
                ),
              ),
              const SizedBox(height: 15),

              // Botón SUBIR DESDE LA GALERÍA (Secundario)
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: Icon(Icons.cloud_upload, color: primaryColor),
                label: Text(
                  'SUBIR DESDE LA GALERÍA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: primaryColor, width: 2),
                ),
              ),

              const SizedBox(height: 30),

              // Botón CONTINUAR
              ElevatedButton(
                onPressed: isPhotoSelected ? _navigateToChoosePlan : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPhotoSelected ? primaryColor : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isPhotoSelected ? 'CONTINUAR' : 'SELECCIONA UNA FOTO',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
