// lib/screens/user_premium/tracking_history_screen.dart

import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/pet.dart';
import '../../services/tracker_service.dart'; // <-- NUEVO
import '../../models/route_history_dto.dart';

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
  final TrackerService _trackerService = TrackerService();
  String _selectedPeriod = 'Semana';
  bool _isLoading = false;

  RouteHistoryDTO? _historyData;

  @override
  void initState() {
    super.initState();
    
    _fetchHistoryData();
  }

  // --- Lógica de Carga de Datos Reales ---
  Future<void> _fetchHistoryData() async {
    setState(() {
      _isLoading = true;
      _historyData = null;
    });

    try {
      final data = await _trackerService.fetchRouteHistory(
        widget.pet.id,
        _selectedPeriod.toLowerCase(),
      );
      if (mounted) {
        setState(() {
          _historyData = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar el historial: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _historyData = RouteHistoryDTO(
            // Establece valores predeterminados en caso de error
            totalDistanceKm: 0.0,
            totalTimeMinutes: 0,
            totalCalories: 0,
            totalRoutes: 0,
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Widgets Auxiliares ---

  // Función para formatear minutos a "Xh Ymin"
  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }

  // 1. Alternadores de Período
  Widget _buildPeriodToggle(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['Semana', 'Mes', 'Año'].map((periodDisplay) {
          final periodValue = periodDisplay.toLowerCase();
          final isSelected = _selectedPeriod == periodValue;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(periodDisplay),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriod = periodValue;
                    _fetchHistoryData(); // <-- LLAMADA AL SERVICIO
                  });
                }
              },
              // ... rest of style ...
            ),
          );
        }).toList(),
      ),
    );
  }

  // ... _buildStatCard (mantener igual) ...
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    // ... implementation ...
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

  // ... _buildWeeklyActivityChart (mantener igual) ...
  Widget _buildWeeklyActivityChart(Color primaryColor) {
    // ... implementation ...
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

  // ... _buildHealthInsights (mantener igual) ...
  Widget _buildHealthInsights(Color primaryColor) {
    // ... implementation ...
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
    // 💡 Usa los datos reales del estado o datos predeterminados si es nulo
    final data =
        _historyData ??
        RouteHistoryDTO(
          totalDistanceKm: 0.0,
          totalTimeMinutes: 0,
          totalCalories: 0,
          totalRoutes: 0,
        );

    final timeValue = _formatTime(data.totalTimeMinutes);

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

                  // Fila de Tarjetas de Estadísticas (2x2) - Usando 'data' real
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildStatCard(
                              title: 'Distancia Total',
                              value: '${data.totalDistanceKm} Km',
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
                              value: '${data.totalCalories.toStringAsFixed(0)}',
                              icon: Icons.trending_up,
                              iconColor: Colors.orange,
                            ),
                            const SizedBox(width: 10),
                            _buildStatCard(
                              title: 'Rutas',
                              value: '${data.totalRoutes}',
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
