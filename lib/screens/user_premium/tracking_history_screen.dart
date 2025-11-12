// lib/screens/user_premium/tracking_history_screen.dart

import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/pet.dart';
// NOTE: Necesitaríamos un modelo 'RouteHistory' y un servicio 'RouteHistoryService' para datos reales.

class TrackingHistoryScreen extends StatefulWidget {
  final User user;
  final Pet pet;

  const TrackingHistoryScreen({
    super.key,
    required this.user,
    required this.pet,
  });

  @override
  State<TrackingHistoryScreen> createState() => _TrackingHistoryScreenState();
}

class _TrackingHistoryScreenState extends State<TrackingHistoryScreen> {
  // Simulación de los períodos (Semana, Mes, Año)
  String _selectedPeriod = 'Semana';
  bool _isLoading = false;

  // --- Datos simulados para la demostración (basados en el diseño) ---
  final Map<String, dynamic> _simulatedData = {
    'Semana': {
      'distance': 39.0, // Km
      'time': 10, // horas
      'minutes': 15, // minutos
      'calories': 1670, // Calorías
      'routes': 12, // Rutas
    },
    'Mes': {
      'distance': 150.5,
      'time': 55,
      'minutes': 30,
      'calories': 7200,
      'routes': 48,
    },
    'Año': {
      'distance': 1800.2,
      'time': 650,
      'minutes': 0,
      'calories': 85000,
      'routes': 550,
    },
  };

  @override
  void initState() {
    super.initState();
    // Simular la carga de datos inicial
    _fetchHistoryData();
  }

  // --- Lógica de Simulación de Carga de Datos ---
  Future<void> _fetchHistoryData() async {
    setState(() {
      _isLoading = true;
    });
    // Simulación de llamada al servicio (que debería usar RouteHistoryController.java)
    await Future.delayed(const Duration(milliseconds: 500)); 
    setState(() {
      _isLoading = false;
    });
  }

  // --- Widgets Auxiliares ---

  // 1. Alternadores de Período (Semana, Mes, Año)
  Widget _buildPeriodToggle(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['Semana', 'Mes', 'Año'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriod = period;
                    // Llamar a _fetchHistoryData si fuera interactivo
                  });
                }
              },
              selectedColor: primaryColor.withOpacity(0.1),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 2. Tarjeta de Estadísticas Clave
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Gráfico de Actividad Semanal (Simulado)
  Widget _buildWeeklyActivityChart(Color primaryColor) {
    // Reemplaza esto con un widget de gráfico real (por ejemplo, usando fl_chart)
    // El diseño solo muestra una simulación de un gráfico de línea.
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actividad Semanal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            // Simulando el área del gráfico
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Gráfico de Distancia Semanal (Simulado)',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Insights de Salud (Simulado)
  Widget _buildHealthInsights(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_border, color: primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Insights de Salud',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),
          const Text(
            'Buddy ha mantenido un nivel de actividad excelente esta semana',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 5),
          const Text(
            'Promedio de ejercicio: 15% más que la semana pasada',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);
    final data = _simulatedData[_selectedPeriod];
    final timeValue =
        '${data['time']}h ${data['minutes']}min'; // Formato de tiempo

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial De Rutas',
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
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPeriodToggle(primaryColor),
                  const SizedBox(height: 20),

                  // Fila de Tarjetas de Estadísticas (2x2)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildStatCard(
                              title: 'Distancia Total',
                              value: '${data['distance']} Km',
                              icon: Icons.alt_route,
                              iconColor: primaryColor,
                            ),
                            const SizedBox(width: 10),
                            _buildStatCard(
                              title: 'Tiempo Activo',
                              value: timeValue,
                              icon: Icons.timer_outlined,
                              iconColor: Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildStatCard(
                              title: 'Calorías',
                              value:
                                  '${data['calories'].toStringAsFixed(0)}',
                              icon: Icons.trending_up,
                              iconColor: Colors.orange,
                            ),
                            const SizedBox(width: 10),
                            _buildStatCard(
                              title: 'Rutas',
                              value: '${data['routes']}',
                              icon: Icons.route_outlined,
                              iconColor: Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  _buildWeeklyActivityChart(primaryColor),
                  _buildHealthInsights(primaryColor),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}