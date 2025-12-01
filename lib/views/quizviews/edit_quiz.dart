import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/services/question_service.dart';
import 'package:quiz_app/services/quiz_services.dart';
import 'package:quiz_app/views/questionviews/addquestion_page.dart';

class EditQuizPage extends StatefulWidget {
  final String quizId;
  final String currentTitle;
  final String currentDesc;

  const EditQuizPage({
    super.key,
    required this.quizId,
    required this.currentTitle,
    required this.currentDesc,
  });

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  final QuizService quizService = QuizService();
  final QuestionService questionService = QuestionService();

  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;

  @override
  void initState() {
    super.initState();
    print("Quiz ID: ${widget.quizId}"); // Add this
    titleCtrl = TextEditingController(text: widget.currentTitle);
    descCtrl = TextEditingController(text: widget.currentDesc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Quiz"),
        backgroundColor: const Color(0xff9d8eff),
      ),
      backgroundColor: const Color(0xffdcd6ff),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // Quiz Title
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                filled: true,
                labelText: "Quiz Title",
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Quiz Description
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                labelText: "Description",
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Add Questions Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddQuestionPage(quizId: widget.quizId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff9d8eff),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Add Questions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // List of Questions
            Expanded(
              child: StreamBuilder(
                stream: questionService.getQuestionsRaw(widget.quizId),
                builder: (context, snapshot) {
                  print("Connection state: ${snapshot.connectionState}");
                  print("Has data: ${snapshot.hasData}");
                  print("Has error: ${snapshot.hasError}");
                    if (snapshot.hasError) {
                      print("Error: ${snapshot.error}");
                    }
                    if (snapshot.hasData) {
                      print("Number of docs: ${snapshot.data!.docs.length}");
                    }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No questions added yet"));
                  }

                  final docs = snapshot.data!.docs;
                  final questions = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return QuestionModel.fromMap(doc.id, data);
                  }).toList();

                  return ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          title: Text(q.question),
                          subtitle: Text(q.options.join(", ")),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddQuestionPage(
                                          quizId: widget.quizId,
                                          existingQuestionId: q.id, // ← The document ID
                                          existingQuestionText: q.question, // ← The actual question text
                                          existingOptions: q.options,
                                          existingCorrectIndex: q.correctIndex,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await questionService.deleteQuestion(
                                      widget.quizId, q.id);
                                  showSnack(context, "Question deleted!");
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Save Quiz Changes Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) {
                    showSnack(context, "Quiz title cannot be empty.");
                    return;
                  }
                  await quizService.updateQuiz(widget.quizId, {
                    "title": titleCtrl.text.trim(),
                    "description": descCtrl.text.trim(),
                  });
                  showSnack(context, "Quiz updated!");
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff9d8eff),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
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
