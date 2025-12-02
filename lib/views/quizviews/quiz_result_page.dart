// lib/views/quiz_result_page.dart
import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/models/quiz_result_model.dart';
import 'package:quiz_app/services/quiz_result_service.dart';


class QuizResultPage extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final List<QuestionModel> questions;
  final Map<String, int> userAnswers;

  const QuizResultPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.questions,
    required this.userAnswers,
  });

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  bool _resultSaved = false;

  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    if (_resultSaved) return;
    
    final resultService = ResultService();
    
    final answersMap = Map<String, dynamic>.from(
      widget.userAnswers.map((key, value) => MapEntry(key, value))
    );
    
    final result = QuizResultModel(
      id: '',
      quizId: widget.quizId,
      quizTitle: widget.quizTitle,
      totalQuestions: widget.totalQuestions,
      correctAnswers: widget.correctAnswers,
      percentage: percentage,
      completedAt: DateTime.now(),
      answers: answersMap,
    );

    await resultService.saveResult(result);
    _resultSaved = true;
    
    print("✅ Saved result for quiz: ${widget.quizTitle} (ID: ${widget.quizId})");
  }

  // Getters to access widget properties easily
  double get percentage => (widget.correctAnswers / widget.totalQuestions) * 100;
  
  String get grade {
    if (percentage >= 90) return "A";
    if (percentage >= 80) return "B";
    if (percentage >= 70) return "C";
    if (percentage >= 60) return "D";
    return "F";
  }

  Color get gradeColor {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Results"),
        backgroundColor: const Color(0xff9d8eff),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xffdcd6ff),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Score Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Your Score",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gradeColor.withOpacity(0.2),
                        border: Border.all(
                          color: gradeColor,
                          width: 8,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              grade,
                              style: TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: gradeColor,
                              ),
                            ),
                            Text(
                              "${percentage.toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: gradeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "${widget.correctAnswers} / ${widget.totalQuestions} Correct",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Review Answers Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  "Review Your Answers",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Question Review List
              ...widget.questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final userAnswer = widget.userAnswers[question.id];
                final isCorrect = userAnswer == question.correctIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isCorrect ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Question ${index + 1}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Show user's answer
                      if (userAnswer != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCorrect 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your Answer:",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCorrect ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                question.options[userAnswer],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      // Show correct answer if user was wrong
                      if (!isCorrect) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Correct Answer:",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                question.options[question.correctIndex],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to quiz list
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff9d8eff),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Back to Quizzes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}