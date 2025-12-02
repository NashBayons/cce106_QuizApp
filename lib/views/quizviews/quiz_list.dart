import 'package:flutter/material.dart';
import 'package:quiz_app/services/quiz_services.dart';
import 'package:quiz_app/views/quizviews/edit_quiz.dart';
import 'package:quiz_app/views/quizviews/take_quiz_page.dart';

class QuizListPage extends StatelessWidget {
  final QuizService quizService = QuizService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Quizzes"),
        backgroundColor: const Color(0xff9d8eff),
      ),
      backgroundColor: const Color(0xffdcd6ff),

      body: StreamBuilder(
        stream: quizService.getQuizzes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No quizzes created yet"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var quiz = docs[index];
              var data = quiz.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Untitled Quiz';
              final description = data['description'] ?? 'No description';
              final isPublic = data['isPublic'] ?? false;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),

                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.play_arrow, color: Colors.green),
                          onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizTakingPage(
                                  quizId: quiz.id,
                                  quizTitle: title,
                              ),
                            ),
                          );
                        },
                      ),
                      // Edit quiz
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditQuizPage(
                                quizId: quiz.id,
                                currentTitle: data['title'],
                                currentDesc: data['description'],
                              ),
                            ),
                          );
                        },
                      ),

                      // Delete quiz
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmDelete(context, quiz.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void confirmDelete(BuildContext context, String quizId) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Quiz"),
          content: const Text("Are you sure you want to delete this quiz?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                quizService.deleteQuiz(quizId);
                Navigator.pop(context);
                showSnack(context, "Quiz deleted successfully");
              },
            ),
          ],
        );
      },
    );
  }
  void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
