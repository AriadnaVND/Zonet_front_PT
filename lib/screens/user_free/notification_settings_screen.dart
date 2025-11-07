// lib/screens/user_free/notification_settings_screen.dart
import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // 💡 ESTADO LOCAL - Simula la persistencia de las preferencias
  bool _receiveNotifications = true;
  bool _receiveReactionNotifications = true;

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00ADB5),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  // Widget reutilizable para los botones de Sí/No
  Widget _buildToggleSwitch(
    String title,
    bool currentValue,
    ValueChanged<bool> onChanged,
  ) {
    const Color primaryColor = Color(0xFF00ADB5);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Row(
              children: [
                _buildButton('Sí', currentValue, (value) {
                  onChanged(value);
                  _showSnackbar('Preferencia guardada.');
                }, primaryColor),
                const SizedBox(width: 8),
                _buildButton('No', !currentValue, (value) {
                  onChanged(!value);
                  _showSnackbar('Preferencia guardada.');
                }, primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Botón individual de Sí/No
  Widget _buildButton(
    String text,
    bool isSelected,
    ValueChanged<bool> onTap,
    Color primaryColor,
  ) {
    return ElevatedButton(
      onPressed: isSelected ? null : () => onTap(true),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? primaryColor : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.grey.shade400,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
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
      backgroundColor: const Color(0xFFEEEEEE),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Recibir Notificaciones
            _buildToggleSwitch(
              'Recibir Notificaciones',
              _receiveNotifications,
              (value) => setState(() => _receiveNotifications = value),
            ),
            const SizedBox(height: 10),

            // Notificaciones de Reacciones (Comunidad)
            _buildToggleSwitch(
              'Notificaciones De Reacciones',
              _receiveReactionNotifications,
              (value) => setState(() => _receiveReactionNotifications = value),
            ),
            const SizedBox(height: 40),

            // Footer
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: const Text(
                  'Zoonet\n© 2024 Zoonet Inc.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
