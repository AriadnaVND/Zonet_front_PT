// lib/services/community_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/community.dart';
import '../models/ai_match_result.dart';
import 'auth_service.dart';

class CommunityService {
  final AuthService _authService = AuthService();

  String _getCommunityBaseUrl() {
    // Reutiliza la lógica base y apunta a /api/community
    return _authService.getPetBaseUrl().replaceFirst(
      '/api/pets',
      '/api/community',
    );
  }

  // 1. Obtener Publicaciones del Feed (GET /api/community/posts)
  Future<List<CommunityPost>> fetchAllPosts(int currentUserId) async {
    final url = Uri.parse('${_getCommunityBaseUrl()}/posts');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) {
          // Crear el modelo de datos
          CommunityPost post = CommunityPost.fromJson(json);

          // Lógica 'userReacted' en el cliente:
          // Verificar si el usuario actual está en la lista de reacciones
          bool reacted =
              json['reactions']?.any((r) => r['user']['id'] == currentUserId) ??
              false;

          return CommunityPost(
            id: post.id,
            postType: post.postType,
            description: post.description,
            imageUrl: post.imageUrl,
            locationName: post.locationName,
            latitude: post.latitude,
            longitude: post.longitude,
            createdAt: post.createdAt,
            userName: post.userName,
            totalReactions: post.totalReactions,
            totalComments: post.totalComments,
            userReacted: reacted, // Asignar el valor calculado
          );
        }).toList();
      } else {
        throw Exception(
          'Fallo al cargar publicaciones: Código ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Fallo de conexión al cargar el feed: ${e.toString()}');
    }
  }

  // 2. Reportar Mascota Perdida (POST /api/pets/lost)
  // Nota: Este endpoint está en /api/pets/lost, no en /api/community.
  Future<Map<String, dynamic>> reportLostPet(Map<String, dynamic> data) async {
    final url = Uri.parse(
      _authService.getPetBaseUrl().replaceFirst('/api/pets', '/api/pets/lost'),
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(data),
      );

      final body = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        return body;
      } else {
        // Captura el error de límite si es un usuario FREE
        throw Exception(
          body['message'] ?? 'Fallo al reportar mascota perdida.',
        );
      }
    } catch (e) {
      throw Exception('Fallo de conexión al reportar mascota: ${e.toString()}');
    }
  }

  // 3. Toggle Reacción (POST /api/community/reactions)
  Future<bool> toggleReaction(int postId, int userId) async {
    final url = Uri.parse('${_getCommunityBaseUrl()}/reactions');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'postId': postId, 'userId': userId}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // Retorna el valor 'isAdded' (true si se añadió el like, false si se quitó)
        return body['isAdded'] == 'true';
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Fallo al procesar la reacción.');
      }
    } catch (e) {
      throw Exception('Fallo de conexión al reaccionar: ${e.toString()}');
    }
  }

  // 4. Añadir Comentario (POST /api/community/comments)
  Future<void> addComment(int postId, int userId, String content) async {
    final url = Uri.parse('${_getCommunityBaseUrl()}/comments');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'postId': postId,
          'userId': userId,
          'content': content, // Coincide con CommentDTO.java
        }),
      );

      if (response.statusCode != 201) {
        // HttpStatus.CREATED
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          errorBody['message'] ?? 'Fallo al añadir el comentario.',
        );
      }
    } catch (e) {
      throw Exception('Fallo de conexión al comentar: ${e.toString()}');
    }
  }

  // 5. 🟢 CORRECCIÓN DEL ERROR: Método público para construir la URL de la imagen
  String buildFullImageUrl(String photoUrlPath) {
    return _authService.buildFullImageUrl(photoUrlPath);
  }

  // 6. 💡 Emparejamiento de Mascotas con IA (POST /api/community/ai-matching/{userId})
  Future<List<AiMatchResult>> findAiMatches(int userId, File photo) async {
    final url = Uri.parse('${_getCommunityBaseUrl()}/ai-matching/$userId');

    var request = http.MultipartRequest('POST', url);

    // El nombre 'photo' debe coincidir exactamente con @RequestParam("photo") en el backend
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo', // 💡 CLAVE: Asegúrese de que esto coincide con el backend.
        photo.path,
        filename: 'search_pet_photo_$userId.jpg',
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    // ... (Manejo de la respuesta, incluido el parseo del cuerpo) ...
    // ... (Cuidado con los mensajes vacíos o listas vacías de matches) ...

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      // El backend puede devolver una lista de matches o un mapa con un mensaje (si no hay matches)
      if (body is List) {
        return body.map((json) => AiMatchResult.fromJson(json)).toList();
      } else if (body is Map && body.containsKey('matches')) {
        return (body['matches'] as List)
            .map((json) => AiMatchResult.fromJson(json))
            .toList();
      } else {
        // Devuelve una lista vacía si el cuerpo es inesperado
        return [];
      }
    } else if (response.statusCode == 403) {
      // HttpStatus.FORBIDDEN (Restricción Premium)
      throw Exception(
        body['error'] ?? 'Acceso denegado. Esta es una función Premium.',
      );
    } else {
      // El error "no se encuentra" del backend debería llegar aquí si devuelve 404/400
      // Y en el modal se muestra el mensaje de error.
      throw Exception(
        body['error'] ??
            body['message'] ??
            'Fallo al buscar coincidencias. Código: ${response.statusCode}',
      );
    }
  }
}
