// lib/models/pet.dart
class Pet {
  final int id;
  final String name;
  final String photoUrl; // Path relativo del servidor (ej: /uploads/foto.png)

  Pet({required this.id, required this.name, required this.photoUrl});

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: (json['id'] as int),
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String,
    );
  }
}
