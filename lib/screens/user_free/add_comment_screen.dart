// lib/screens/user_free/add_comment_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/community.dart';
import '../../services/community_service.dart';
import 'package:timeago/timeago.dart' as timeago; // Para formatear la fecha

class AddCommentScreen extends StatefulWidget {
  final CommunityPost post;
  final User user;
  final VoidCallback onCommentAdded;

  const AddCommentScreen({
    super.key,
    required this.post,
    required this.user,
    required this.onCommentAdded,
  });

  @override
  State<AddCommentScreen> createState() => _AddCommentScreenState();
}

class _AddCommentScreenState extends State<AddCommentScreen> {
  final TextEditingController _contentController = TextEditingController();
  final CommunityService _communityService = CommunityService();
  bool _isLoading = false;
  late List<dynamic> _comments;

  @override
  void initState() {
    super.initState();
    // Accede a la lista de comentarios del post (ya cargada)
    _comments = widget.post.comments ?? [];
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_contentController.text.trim().isEmpty) {
      _showSnackbar('El comentario no puede estar vacío.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Llama al nuevo método del servicio
      await _communityService.addComment(
        widget.post.id,
        widget.user.id!,
        _contentController.text.trim(),
      );

      widget.onCommentAdded(); // Llama al callback para refrescar la lista
      _showSnackbar('Comentario publicado correctamente.', isError: false);
      if (mounted) Navigator.pop(context); // Cierra la pantalla
    } catch (e) {
      _showSnackbar(
        'Error: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
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

  // 💡 NUEVO WIDGET: Mostrar un solo comentario
  Widget _buildCommentTile(Map<String, dynamic> commentData) {
    final userName = commentData['user']['name'] as String;
    final content = commentData['content'] as String;
    final createdAt = DateTime.parse(commentData['createdAt'] as String);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, child: Text(userName.substring(0, 1))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(createdAt, locale: 'es'),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Text(content, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          // Mostrar el nombre del autor del post (se asume que userName existe)
          'Comentar en ${widget.post.userName.split(' ').first}\'s Post',
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: <Widget>[
          // 1. Área de Comentarios Existentes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16.0),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                // Asumimos que los comentarios vienen como Map<String, dynamic>
                return _buildCommentTile(
                  _comments[index] as Map<String, dynamic>,
                );
              },
            ),
          ),

          // 2. Área de Input del Nuevo Comentario (Fija en la parte inferior)
          Container(
            padding: EdgeInsets.fromLTRB(
              16.0,
              8.0,
              16.0,
              MediaQuery.of(context).viewInsets.bottom + 8.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _contentController,
                  autofocus:
                      false, // Desactivamos el autofoco para no cubrir la lista
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu comentario...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Botón de Publicar
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'PUBLICAR COMENTARIO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
