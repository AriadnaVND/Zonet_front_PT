// lib/models/route_history_dto.dart
class RouteHistoryDTO {
  final double totalDistanceKm;
  final int totalTimeMinutes;
  final int totalCalories;
  final int totalRoutes;

  RouteHistoryDTO({
    required this.totalDistanceKm,
    required this.totalTimeMinutes,
    required this.totalCalories,
    required this.totalRoutes,
  });

  factory RouteHistoryDTO.fromJson(Map<String, dynamic> json) {
    return RouteHistoryDTO(
      // Se utiliza (json as num).toDouble() para manejar tipos Int que vienen de JSON
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      totalTimeMinutes: (json['totalTimeMinutes'] as num).toInt(),
      totalCalories: (json['totalCalories'] as num).toInt(),
      totalRoutes: (json['totalRoutes'] as num).toInt(),
    );
  }
}
