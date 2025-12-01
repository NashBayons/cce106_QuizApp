import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/services/question_service.dart';

class AddQuestionPage extends StatefulWidget {
  final String quizId;
  final String? existingQuestionId; // ← Renamed for clarity
  final String? existingQuestionText;
  final List<String>? existingOptions;
  final int? existingCorrectIndex;

  const AddQuestionPage({
    super.key,
    required this.quizId,
    this.existingQuestionId, // ← For update/delete operations
    this.existingQuestionText, // ← For pre-filling the text field
    this.existingOptions,
    this.existingCorrectIndex,
  });

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final QuestionService questionService = QuestionService();
  final TextEditingController questionCtrl = TextEditingController();
  List<TextEditingController> optionCtrls = [];
  int correctIndex = 0;

  @override
  void initState() {
    super.initState();
    questionCtrl.text = widget.existingQuestionText ?? '';
    correctIndex = widget.existingCorrectIndex ?? 0;

    // Initialize option controllers
    if (widget.existingOptions != null) {
      optionCtrls = widget.existingOptions!.map((opt) => TextEditingController(text: opt)).toList();
    } else {
      optionCtrls = List.generate(4, (_) => TextEditingController());
    }
  }

  @override
  void dispose() {
    questionCtrl.dispose();
    for (var ctrl in optionCtrls) ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
    appBar: AppBar(
      title: Text(widget.existingQuestionId == null ? "Add Question" : "Edit Question"),
      backgroundColor: const Color(0xff9d8eff),
    ),
    body: Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          TextField(
            controller: questionCtrl,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: "Question",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Options (Select the correct answer)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...List.generate(optionCtrls.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Radio<int>(
                    value: index,
                    groupValue: correctIndex,
                    onChanged: (value) {
                      setState(() {
                        correctIndex = value!;
                      });
                    },
                    activeColor: const Color(0xff9d8eff),
                  ),
                  Expanded(
                    child: TextField(
                      controller: optionCtrls[index],
                      decoration: InputDecoration(
                        labelText: "Option ${index + 1}",
                        filled: true,
                        fillColor: correctIndex == index 
                            ? const Color(0xffe8e3ff) // Highlight correct answer
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: correctIndex == index 
                                ? const Color(0xff9d8eff)
                                : Colors.grey,
                            width: correctIndex == index ? 2 : 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: correctIndex == index 
                                ? const Color(0xff9d8eff)
                                : Colors.grey.shade300,
                            width: correctIndex == index ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
                final questionText = questionCtrl.text.trim();
                final options = optionCtrls.map((e) => e.text.trim()).toList();

                if (questionText.isEmpty || options.any((o) => o.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")));
                  return;
                }

                final question = QuestionModel(
                  id: widget.existingQuestionId ?? '',
                  quizId: widget.quizId,
                  question: questionText,
                  options: options,
                  correctIndex: correctIndex,
                );

                if (widget.existingQuestionId == null) {
                  await questionService.addQuestion(widget.quizId, question);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Question added!")));
                } else {
                  await questionService.updateQuestion(
                      widget.quizId, widget.existingQuestionId!, question.toMap());
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Question updated!")));
                }

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff9d8eff),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                widget.existingQuestionId == null ? "Add Question" : "Save Changes",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    ),
  );
  }
}
