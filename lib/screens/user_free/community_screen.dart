// lib/screens/user_free/community_screen.dart

import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/community.dart';
import '../../services/community_service.dart';
import '../../models/pet.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'add_comment_screen.dart';
import 'report_lost_pet_modal.dart';

class CommunityScreen extends StatefulWidget {
  final User user;
  final Pet pet;

  const CommunityScreen({super.key, required this.user, required this.pet});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();
  List<CommunityPost> _posts = [];
  bool _isLoading = true;

  // 💡 Límite de reportes para usuarios FREE (lo obtienes del backend)
  // Como el backend solo valida 3 y el mensaje de la UI es genérico, lo dejamos fijo.
  final int _freeReportLimit = 3;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final posts = await _communityService.fetchAllPosts(widget.user.id!);
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      _showSnackbar(
        'Error al cargar la comunidad: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : const Color(0xFF00ADB5),
        ),
      );
    }
  }

  // 🟢 Lógica de Navegación para Comentar
  void _navigateToCommentScreen(CommunityPost post) {
    // Navegar a la nueva pantalla de comentarios
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCommentScreen(
          post: post,
          user: widget.user,
          onCommentAdded: _fetchPosts, // Refresca el feed al volver
        ),
      ),
    );
  }

  // --- Lógica para el botón de Reportar Mascota Perdida (Simulación) ---
  Future<void> _handleReportLostPet() async {
    // 🟢 CORRECCIÓN: Mostrar el formulario modal
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Para que el modal se ajuste al teclado
      builder: (context) {
        return Padding(
          // Ajustar el padding para el teclado virtual
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ReportLostPetModal(
            userId: widget.user.id!,
            pet: widget.pet,
            onReportSent: _fetchPosts, // Refresca el feed al enviar el reporte
          ),
        );
      },
    );
  }

  // --- Lógica para el botón de Reacción (Like/Unlike) ---
  Future<void> _handleToggleReaction(CommunityPost post) async {
    try {
      final isAdded = await _communityService.toggleReaction(
        post.id,
        widget.user.id!,
      );

      // Actualizar el estado local para un 'feedback' instantáneo
      setState(() {
        final index = _posts.indexOf(post);
        if (index != -1) {
          // Crear una nueva instancia de CommunityPost con los datos actualizados
          _posts[index] = CommunityPost(
            id: post.id,
            postType: post.postType,
            description: post.description,
            imageUrl: post.imageUrl,
            locationName: post.locationName,
            latitude: post.latitude,
            longitude: post.longitude,
            createdAt: post.createdAt,
            userName: post.userName,
            totalReactions:
                post.totalReactions +
                (isAdded ? 1 : -1), // +1 si se añadió, -1 si se quitó
            totalComments: post.totalComments,
            userReacted: isAdded, // Cambia el estado de reacción del usuario
          );
        }
      });
    } catch (e) {
      _showSnackbar(
        'Error al reaccionar: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }

  // --- Widgets de la Interfaz ---

  // Botón rojo de Reportar Mascota Perdida
  Widget _buildReportButton() {
    
    const Color emergencyColor = Color(0xFFE57373);

    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: Center(
        child: ElevatedButton.icon(
          // 🟢 CORRECCIÓN: Llamar al manejador del modal
          onPressed: _handleReportLostPet,
          icon: Icon(Icons.pets, color: Colors.white),
          label: const Text(
            // Elimina el indicador de carga local
            'REPORTAR MASCOTA PERDIDA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: emergencyColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 3,
          ),
        ),
      ),
    );
  }

  // Tarjeta de Publicación
  Widget _buildPostCard(CommunityPost post) {
    const Color primaryColor = Color(0xFF00ADB5);

    // La imagen se asume que se construye con la URL completa
    final String fullImageUrl = _communityService.buildFullImageUrl(
      post.imageUrl,
    );

    // Lógica para mostrar la hora
    final timeAgo = timeago.format(post.createdAt, locale: 'es');

    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del Post (Sara M. Hace X horas. Brooklyn Bridge Park)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${post.userName.split(' ').first} M.', // Usar solo el primer nombre + inicial
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Hace ${timeAgo}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  post.locationName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Descripción del Post
            Text(post.description, style: const TextStyle(fontSize: 14)),

            const SizedBox(height: 10),

            // Imagen del Post
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                fullImageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Text('Error al cargar imagen')),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Pie de Post (Comentarios y Reacciones)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  // 🟢 NAVEGACIÓN A COMENTARIOS
                  onPressed: () => _navigateToCommentScreen(post),
                  icon: const Icon(
                    Icons.comment_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  label: Text(
                    '${post.totalComments} Comentario${post.totalComments != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _handleToggleReaction(post),
                  icon: Icon(
                    post.userReacted ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: post.userReacted ? Colors.red : Colors.grey,
                  ),
                  label: Text(
                    '${post.totalReactions} Reaccion${post.totalReactions != 1 ? 'es' : ''}',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Mensaje de Límite de Reportes para FREE
  Widget _buildLimitWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blueGrey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          'RECUERDA TIENES UN LÍMITE DE $_freeReportLimit REPORTES',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFEEEEEE), // Fondo gris de la imagen
      body: Column(
        children: [
          _buildReportButton(),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(_posts[index]);
                    },
                  ),
          ),

          // El mensaje de límite va al final, debajo del feed
          _buildLimitWarning(),
        ],
      ),
    );
  }
}
