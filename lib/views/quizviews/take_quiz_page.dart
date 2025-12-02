// lib/views/quiz_taking_page.dart
import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/services/question_service.dart';
import 'package:quiz_app/views/quizviews/quiz_result_page.dart';

class QuizTakingPage extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizTakingPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage> {
  final QuestionService questionService = QuestionService();
  
  List<QuestionModel> questions = [];
  Map<String, int> userAnswers = {}; // questionId -> selected option index
  int currentQuestionIndex = 0;
  bool isLoading = true;
  int? selectedOption;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    // Get all questions as a one-time fetch
    final snapshot = await questionService.getQuestionsRaw(widget.quizId).first;
    setState(() {
      questions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return QuestionModel.fromMap(doc.id, data);
      }).toList();
      isLoading = false;
    });
  }

  void selectOption(int index) {
    setState(() {
      selectedOption = index;
    });
  }

  void nextQuestion() {
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an answer")),
      );
      return;
    }

    // Save the answer
    userAnswers[questions[currentQuestionIndex].id] = selectedOption!;

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOption = userAnswers[questions[currentQuestionIndex].id];
      });
    } else {
      // Quiz finished, show results
      navigateToResults();
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        selectedOption = userAnswers[questions[currentQuestionIndex].id];
      });
    }
  }

  void navigateToResults() {
    int correctCount = 0;
    for (var question in questions) {
      if (userAnswers[question.id] == question.correctIndex) {
        correctCount++;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPage(
          quizTitle: widget.quizTitle,
          quizId: widget.quizId, // ← Add this
          totalQuestions: questions.length,
          correctAnswers: correctCount,
          questions: questions,
          userAnswers: userAnswers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Take Quiz"),
          backgroundColor: const Color(0xff9d8eff),
        ),
        body: const Center(
          child: Text(
            "No questions available in this quiz",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),
        backgroundColor: const Color(0xff9d8eff),
      ),
      backgroundColor: const Color(0xffdcd6ff),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff9d8eff)),
            minHeight: 8,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Counter
                Text(
                  "Question ${currentQuestionIndex + 1} of ${questions.length}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff9d8eff),
                  ),
                ),
                const SizedBox(height: 20),
                // Question Text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    currentQuestion.question,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Options
                ...List.generate(currentQuestion.options.length, (index) {
                  final isSelected = selectedOption == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: InkWell(
                      onTap: () => selectOption(index),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xff9d8eff)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xff9d8eff)
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          currentQuestion.options[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 30),
                // Navigation Buttons
                Row(
                  children: [
                    if (currentQuestionIndex > 0)
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: previousQuestion,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xff9d8eff), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              "Previous",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xff9d8eff),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (currentQuestionIndex > 0) const SizedBox(width: 15),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: nextQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff9d8eff),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            currentQuestionIndex < questions.length - 1 
                                ? "Next" 
                                : "Finish",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}