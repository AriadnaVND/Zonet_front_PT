// lib/models/location.dart
class PetLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  PetLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory PetLocation.fromJson(Map<String, dynamic> json) {
    return PetLocation(
      // La latitud y longitud vienen como double
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      // El timestamp de Java/Spring se mapea a DateTime
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}