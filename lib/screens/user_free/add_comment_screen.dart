// lib/screens/user_free/add_comment_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/community.dart';
import '../../services/community_service.dart';

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

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00ADB5);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comentar en ${widget.post.userName.split(' ').first}\'s Post',
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Muestra una vista previa del post
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ListTile(
                title: Text(
                  widget.post.description.length > 50
                      ? '${widget.post.description.substring(0, 50)}...'
                      : widget.post.description,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Autor: ${widget.post.userName.split(' ').first}',
                ),
                trailing: const Icon(Icons.forum, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // Campo de texto para el comentario
            TextField(
              controller: _contentController,
              autofocus: true,
              maxLines: 4,
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
            const SizedBox(height: 20),

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
    );
  }
}
