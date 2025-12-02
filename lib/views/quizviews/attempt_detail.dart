// lib/views/results/attempt_detail_page.dart
import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/models/quiz_result_model.dart';
import 'package:quiz_app/services/question_service.dart';
import 'package:quiz_app/services/quiz_result_service.dart';
import 'package:intl/intl.dart';

class AttemptDetailPage extends StatefulWidget {
  final String resultId;

  const AttemptDetailPage({
    super.key,
    required this.resultId,
  });

  @override
  State<AttemptDetailPage> createState() => _AttemptDetailPageState();
}

class _AttemptDetailPageState extends State<AttemptDetailPage> {
  final ResultService resultService = ResultService();
  final QuestionService questionService = QuestionService();

  bool isLoading = true;
  QuizResultModel? result;
  List<QuestionModel> questions = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    result = await resultService.getResultById(widget.resultId);
    
    if (result != null) {
      // Load questions for this quiz
      final snapshot = await questionService.getQuestionsRaw(result!.quizId).first;
      questions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return QuestionModel.fromMap(doc.id, data);
      }).toList();
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (result == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Attempt Details"),
          backgroundColor: const Color(0xff9d8eff),
        ),
        body: const Center(child: Text("Result not found")),
      );
    }

    final color = _getScoreColor(result!.percentage);
    final grade = _getGrade(result!.percentage);
    final dateStr = DateFormat('MMMM dd, yyyy - hh:mm a')
        .format(result!.completedAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attempt Details"),
        backgroundColor: const Color(0xff9d8eff),
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
                    Text(
                      result!.quizTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.2),
                        border: Border.all(
                          color: color,
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
                                color: color,
                              ),
                            ),
                            Text(
                              "${result!.percentage.toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "${result!.correctAnswers} / ${result!.totalQuestions} Correct",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Review Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  "Answer Review",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Questions Review
              ...questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final userAnswerIndex = result!.answers[question.id];
                final isCorrect = userAnswerIndex == question.correctIndex;

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
                      // User's answer
                      if (userAnswerIndex != null)
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
                                question.options[userAnswerIndex],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      // Correct answer if wrong
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
            ],
          ),
        ),
      ),
    );
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return "A";
    if (percentage >=80)  return "B";
    if (percentage >= 70) return "C";
    if (percentage >= 60) return "D";
    return "F";
    }

    Color _getScoreColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
    }
    }