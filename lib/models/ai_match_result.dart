// lib/models/ai_match_result.dart
// DTO que representa un resultado de coincidencia de IA
class AiMatchResult {
  final int postId;
  final String petName;
  final String description;
  final String imageUrl;
  final String locationName;
  final String timeAgo;
  final int matchPercentage;
  final String aiReasoning;

  AiMatchResult({
    required this.postId,
    required this.petName,
    required this.description,
    required this.imageUrl,
    required this.locationName,
    required this.timeAgo,
    required this.matchPercentage,
    required this.aiReasoning,
  });

  factory AiMatchResult.fromJson(Map<String, dynamic> json) {
    return AiMatchResult(
      postId: (json['postId'] as num).toInt(),
      petName: json['petName'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      locationName: json['locationName'] as String,
      timeAgo: json['timeAgo'] as String,
      matchPercentage: (json['matchPercentage'] as num).toInt(),
      aiReasoning: json['aiReasoning'] as String,
    );
  }
}
