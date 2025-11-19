// lib/screens/user_free/profile_settings_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/pet.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart'; // Para cerrar sesión

class ProfileSettingsScreen extends StatefulWidget {
  final User user;
  final Pet pet;

  const ProfileSettingsScreen({
    super.key,
    required this.user,
    required this.pet,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  // Asume que esta URL es la foto del perfil/mascota del usuario logeado
  late String _profileImageUrl;
  bool _isEditingPersonal = false;
  bool _isEditingSecurity = false;
  bool _isLoadingPersonal = false;
  bool _isLoadingSecurity = false;
  bool _isDeleting = false;

  // Controladores de edición
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  final TextEditingController _newPasswordController = TextEditingController();

  // Asumiendo que el usuario está siempre disponible en widget.user
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    // Usar la foto de la mascota como foto de perfil del usuario (en el contexto de Zoonet)
    _profileImageUrl = _authService.buildFullImageUrl(widget.pet.photoUrl);
    _nameController.text = _currentUser.name ?? '';
    _emailController.text = _currentUser.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();

    _newPasswordController.dispose();
    super.dispose();
  }

  // --- Lógica de Manejo de Eventos ---

  // 1. Cerrar Sesión
  void _handleLogout() {
    // 💡 Lógica simple: limpiar datos locales y redirigir al Login
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
      _showSnackbar('Sesión cerrada correctamente.', isError: false);
    }
  }

  // 2. Simulación: Guardar Información Personal
  Future<void> _handleSavePersonal() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      _showSnackbar(
        'El nombre y el email no pueden estar vacíos.',
        isError: true,
      );
      return;
    }

    if (_nameController.text == _currentUser.name &&
        _emailController.text == _currentUser.email) {
      setState(() => _isEditingPersonal = false);
      _showSnackbar('No hay cambios para guardar.', isError: false);
      return;
    }

    setState(() {
      _isLoadingPersonal = true;
    });

    try {
      final updatedUser = await _userService.updateProfile(
        _currentUser.id!,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: null, // No se cambia la contraseña aquí
      );

      setState(() {
        _isEditingPersonal = false;
        _currentUser = updatedUser; // Actualiza el objeto User en el estado
      });

      _showSnackbar('Información personal actualizada.', isError: false);
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnackbar('Error al actualizar: $errorMessage', isError: true);
      // Revertir a valores originales en caso de error
      _nameController.text = _currentUser.name ?? '';
      _emailController.text = _currentUser.email ?? '';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPersonal = false;
        });
      }
    }
  }

  // 3. Cambiar Contraseña
  Future<void> _handleSavePassword() async {
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.length < 6) {
      _showSnackbar(
        'La nueva contraseña debe tener al menos 6 caracteres.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoadingSecurity = true;
    });

    try {
      // El backend requiere al menos un campo, enviamos solo la nueva contraseña
      await _userService.updateProfile(
        _currentUser.id!,
        name: null,
        email: null,
        password: newPassword,
      );

      setState(() {
        _isEditingSecurity = false;
        _newPasswordController.clear();
      });
      _showSnackbar('Contraseña cambiada exitosamente.', isError: false);
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnackbar(
        'Error al cambiar contraseña: $errorMessage',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSecurity = false;
        });
      }
    }
  }

  // 4. Eliminar Cuenta
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar tu cuenta permanentemente? Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Eliminar Cuenta',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _handleDeleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _userService.deleteAccount(
        _currentUser.id!,
      ); // Llama al DELETE real

      _handleLogout(); // Redirige al login después de la eliminación exitosa
      _showSnackbar('Cuenta eliminada correctamente.', isError: false);
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      _showSnackbar(
        'Fallo al eliminar la cuenta: $errorMessage',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
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

  // --- Widgets Auxiliares de Diseño ---

  Widget _buildField({
    required IconData icon,
    required TextEditingController controller,
    required bool isEditable,
    bool isEmail = false,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        enabled: isEditable,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
        ),
        style: TextStyle(
          color: isEditable ? Colors.black : Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Contenedor de las secciones (Información Personal y Seguridad)
  Widget _buildSectionCard({
    required String title,
    required IconData titleIcon,
    required Widget content,
    required bool isEditing,
    required VoidCallback onEditPressed,
    required VoidCallback onSavePressed,
    required Color primaryColor,
    required bool isLoading,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header de la Sección (Título y Botón Editar/Guardar)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(titleIcon, color: primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: isEditing ? onSavePressed : onEditPressed,
                        child: Text(
                          isEditing ? 'Guardar' : 'Editar',
                          style: TextStyle(
                            color: isEditing ? Colors.green : primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
            const Divider(height: 20),

            // Contenido de la Sección
            content,
          ],
        ),
      ),
    );
  }

  // --- UI Principal ---
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text(
          'Configuración De Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Foto de Perfil (Mantenida como simulación por simplicidad)
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundImage: NetworkImage(_profileImageUrl),
                          backgroundColor: Colors.grey[300],
                        ),
                        GestureDetector(
                          onTap: () {
                            _showSnackbar(
                              'Cambiando foto de perfil... (No implementado en el backend)',
                              isError: false,
                            );
                            // TODO: Implementar lógica de cambio de foto
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: primaryColor,
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Sección de Información Personal
                  _buildSectionCard(
                    primaryColor: primaryColor,
                    title: 'Información Personal',
                    titleIcon: Icons.person_outline,
                    isEditing: _isEditingPersonal,
                    onEditPressed: () =>
                        setState(() => _isEditingPersonal = true),
                    onSavePressed: _handleSavePersonal,
                    isLoading: _isLoadingPersonal,
                    content: Column(
                      children: [
                        _buildField(
                          icon: Icons.person,
                          controller: _nameController,
                          isEditable: _isEditingPersonal,
                        ),
                        _buildField(
                          icon: Icons.email,
                          controller: _emailController,
                          isEditable: _isEditingPersonal,
                          isEmail: true,
                        ),
                      ],
                    ),
                  ),

                  // 2. Sección de Seguridad
                  _buildSectionCard(
                    primaryColor: primaryColor,
                    title: 'Cambiar Contraseña',
                    titleIcon: Icons.lock_outline,
                    isEditing: _isEditingSecurity,
                    onEditPressed: () =>
                        setState(() => _isEditingSecurity = true),
                    onSavePressed: _handleSavePassword,
                    isLoading: _isLoadingSecurity,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isEditingSecurity)
                          _buildField(
                            icon: Icons.lock,
                            controller: _newPasswordController,
                            isEditable: true,
                            isPassword: true,
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Presiona "Editar" para cambiar tu contraseña',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 3. Botones de Acción
                  ElevatedButton.icon(
                    onPressed: _isDeleting ? null : _confirmDeleteAccount,
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: Text(
                      _isDeleting ? 'ELIMINANDO...' : 'ELIMINAR CUENTA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFE57373,
                      ), // Color rojo de emergencia
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: Colors.black),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Colors.black54, width: 1),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
