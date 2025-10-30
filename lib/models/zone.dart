// lib/models/zone.dart
class Zone {
  final int? id;
  final int userId;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String address;

  Zone({
    this.id,
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.address,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'address': address,
    };
  }
}