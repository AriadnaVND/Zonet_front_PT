// lib/screens/user_free/community_screen.dart

import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/community.dart';
import '../../services/community_service.dart';
import '../../models/pet.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'add_comment_screen.dart';
import 'report_lost_pet_modal.dart';
import '../community_ai_matching_modal.dart';
import '../plans/choose_plan_screen.dart';

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

      // 💡 CORRECCIÓN
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackbar(
        'Error al cargar la comunidad: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  // 💡 COMPLEMENTO CRÍTICO: Método para llamar al servicio de Marcar como Encontrado
  Future<void> _markAsFound(int postId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Llama al servicio que utiliza el endpoint PUT /api/pets/lost/{reportId}/found
      await _communityService.markAsFound(postId);
      _showSnackbar(
        '¡Felicidades! Mascota marcada como encontrada.',
        isError: false,
      );
      _fetchPosts(); // Recarga el feed para que la publicación desaparezca
    } catch (e) {
      _showSnackbar(
        'Error al marcar como encontrado: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
      // Solo desactiva la carga si hubo un error
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🟢 Lógica de Navegación para ir a la pantalla de planes (si es FREE)
  void _navigateToPlansScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChoosePlanScreen(
          userId: widget.user.id!,
          petName: widget.pet.name,
          imageFile: null,
          existingPhotoUrl: widget.pet.photoUrl,
        ),
      ),
    );
  }

  // --- Lógica para el botón de AI Matching (SOLO Premium) ---
  void _handleAiMatching() {
    final isPremium = widget.user.plan?.toUpperCase() == 'PREMIUM';

    if (isPremium) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityAiMatchingModal(
            user: widget.user,
            pet: widget.pet,
            isPremium: isPremium,
          ),
        ),
      );
    } else {
      _showSnackbar(
        'AI Matching es una función exclusiva para usuarios Premium.',
        isError: true,
      );
      _navigateToPlansScreen();
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

  // 💡 NUEVO: Botón de Emparejamiento con IA (SOLO en la parte inferior)
  Widget _buildAiMatchingButton() {
    final isPremium = widget.user.plan?.toUpperCase() == 'PREMIUM';
    const Color primaryColor = Color(0xFF00ADB5);
    const Color accentColor = Color(0xFF547C87); // Tono secundario del diseño

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isPremium ? primaryColor : accentColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleAiMatching,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Matching',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isPremium
                          ? 'Encuentra mascotas perdidas con IA.'
                          : 'Exclusivo Premium. ¡Mejora tu plan!',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Icon(Icons.smart_toy_outlined, color: Colors.white, size: 30),
              ],
            ),
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

    // 💡 LÓGICA REFINADA: Determinar si es una alerta de pérdida y si el usuario actual es el autor.
    final bool isLostAlert = post.postType == 'LOST_ALERT';
    // Compara el nombre completo, asumiendo que el nombre completo es único en el contexto del usuario.
    // (Idealmente se usaría post.userId == widget.user.id!)
    final bool isMyLostAlert = isLostAlert && post.userName == widget.user.name;

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
                      // Muestra solo el primer nombre y la inicial del apellido
                      '${post.userName.split(' ').first} ${post.userName.split(' ').length > 1 ? post.userName.split(' ')[1].substring(0, 1) + '.' : ''}',
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

            // Pie de Post (Comentarios, Reacciones y Botón Condicional)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
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
                        post.userReacted
                            ? Icons.favorite
                            : Icons.favorite_border,
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

                // 💡 BOTÓN "MARCAR COMO ENCONTRADO"
                if (isMyLostAlert)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _markAsFound(post.id),
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      label: Text(
                        'MARCAR COMO ENCONTRADO',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        minimumSize: Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
          // Botón de Emparejamiento con IA
          _buildAiMatchingButton(),

          // El mensaje de límite va al final, debajo del feed
          _buildLimitWarning(),
        ],
      ),
    );
  }
}
