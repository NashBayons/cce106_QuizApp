// lib/views/quiz_result_page.dart
import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/models/quiz_result_model.dart';
import 'package:quiz_app/services/quiz_result_service.dart';
import 'package:quiz_app/theme/app_theme.dart';
import 'package:quiz_app/views/quizviews/take_quiz_page.dart';


class QuizResultPage extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final List<QuestionModel> questions;
  final Map<String, dynamic> userAnswers;

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
    
    final answersMap = Map<String, dynamic>.from(widget.userAnswers);
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
    if (percentage >= 90) return AppTheme.accentColor;
    if (percentage >= 80) return AppTheme.accentColor;
    if (percentage >= 70) return AppTheme.warningColor;
    if (percentage >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        title: const Text(
          "Quiz Results",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Your Score",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gradeColor.withOpacity(0.12),
                        border: Border.all(
                          color: gradeColor,
                          width: 6,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              grade,
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: gradeColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${percentage.toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: gradeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${widget.correctAnswers} / ${widget.totalQuestions} Correct",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Review Answers Section Header
              Text(
                "Review Your Answers",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Question Review List
              ...widget.questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final dynamic userAnswer = widget.userAnswers[question.id];
                final bool isIdentification =
                    question.questionType == 'identification';

                bool isCorrect;
                String userAnswerText;
                String correctAnswerText;

                if (isIdentification) {
                  final correctText = question.options.isNotEmpty
                      ? question.options.first
                      : '';
                  final typedText =
                      userAnswer is String ? userAnswer : '';
                  userAnswerText =
                      typedText.isEmpty ? 'No answer provided' : typedText;
                  correctAnswerText = correctText.isEmpty
                      ? 'No answer stored'
                      : correctText;
                  isCorrect = typedText.isNotEmpty &&
                      _normalize(typedText) == _normalize(correctText);
                } else {
                  final selectedIndex = userAnswer is int ? userAnswer : null;
                  isCorrect = selectedIndex == question.correctIndex;
                  userAnswerText = (selectedIndex != null &&
                          selectedIndex >= 0 &&
                          selectedIndex < question.options.length)
                      ? question.options[selectedIndex]
                      : 'No answer selected';
                  correctAnswerText = question.options.isNotEmpty
                      ? question.options[question.correctIndex]
                      : 'No correct answer set';
                }

                final answerColor = isCorrect ? AppTheme.accentColor : AppTheme.errorColor;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: answerColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: answerColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: answerColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Question ${index + 1}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        question.question,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: answerColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: answerColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle_outline : Icons.error_outline,
                                  color: answerColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Your Answer:",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: answerColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userAnswerText,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.accentColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppTheme.accentColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Correct Answer:",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                correctAnswerText,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: BorderSide(
                          color: AppTheme.borderColor,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Back to Quizzes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to retry the quiz
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizTakingPage(
                              quizId: widget.quizId,
                              quizTitle: widget.quizTitle,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Retry Quiz",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}