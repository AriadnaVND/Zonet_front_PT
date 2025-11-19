// lib/models/community.dart
class CommunityPost {
  final int id;
  final String postType;
  final String description;
  final String imageUrl;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String userName; // Nombre del usuario autor
  final int totalReactions; // Cantidad de likes/reacciones
  final int totalComments; // Cantidad de comentarios
  final bool userReacted; // Indica si el usuario actual ya reaccionó

  final List<dynamic>? comments; 
  final List<dynamic>? reactions;

  CommunityPost({
    required this.id,
    required this.postType,
    required this.description,
    required this.imageUrl,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.userName,
    required this.totalReactions,
    required this.totalComments,
    required this.userReacted,
    this.comments, 
    this.reactions,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {

    final List<dynamic> commentsList = json['comments'] ?? [];
    final List<dynamic> reactionsList = json['reactions'] ?? [];

    return CommunityPost(
      id: json['id'] as int,
      postType: json['postType'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      locationName: json['locationName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      userName:
          json['user']['name'] as String, // Asumiendo que User es sub-objeto
      totalReactions:
          json['reactions'].length as int, // Usamos la lista de reacciones
      totalComments:
          json['comments'].length as int, // Usamos la lista de comentarios
      // NOTA: 'userReacted' se debe calcular en el frontend o con un DTO más avanzado.
      // Por simplicidad inicial, dejaremos el valor en 'false' y lo actualizamos luego.
      userReacted: false,

      comments: commentsList, 
      reactions: reactionsList,
    );
  }
}
