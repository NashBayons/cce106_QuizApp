// lib/views/quiz_taking_page.dart
import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/services/question_service.dart';
import 'package:quiz_app/theme/app_theme.dart';
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
  Map<String, dynamic> userAnswers = {}; // questionId -> selected option index or text answer
  int currentQuestionIndex = 0;
  bool isLoading = true;
  int? selectedOption;
  final TextEditingController identificationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  @override
  void dispose() {
    identificationCtrl.dispose();
    super.dispose();
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
      if (questions.isNotEmpty) {
        _syncControllersWithCurrentQuestion();
      }
    });
  }

  void _syncControllersWithCurrentQuestion() {
    if (questions.isEmpty) return;
    final currentQuestion = questions[currentQuestionIndex];
    if (_isIdentification(currentQuestion)) {
      final saved = userAnswers[currentQuestion.id] as String?;
      identificationCtrl.text = saved ?? '';
      selectedOption = null;
    } else {
      identificationCtrl.clear();
      final saved = userAnswers[currentQuestion.id];
      selectedOption = saved is int ? saved : null;
    }
  }

  bool _isIdentification(QuestionModel question) =>
      question.questionType == 'identification';

  void selectOption(int index) {
    setState(() {
      selectedOption = index;
    });
  }

  bool _persistCurrentAnswer({bool requireAnswer = true}) {
    final currentQuestion = questions[currentQuestionIndex];
    if (_isIdentification(currentQuestion)) {
      final answer = identificationCtrl.text.trim();
      if (answer.isEmpty) {
        if (requireAnswer) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please type your answer")),
          );
        }
        if (!requireAnswer) {
          userAnswers.remove(currentQuestion.id);
        }
        return !requireAnswer;
      }
      userAnswers[currentQuestion.id] = answer;
      return true;
    } else {
      if (selectedOption == null) {
        if (requireAnswer) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select an answer")),
          );
        }
        if (!requireAnswer) {
          userAnswers.remove(currentQuestion.id);
        }
        return !requireAnswer;
      }
      userAnswers[currentQuestion.id] = selectedOption!;
      return true;
    }
  }

  void nextQuestion() {
    if (!_persistCurrentAnswer(requireAnswer: true)) {
      return;
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _syncControllersWithCurrentQuestion();
      });
    } else {
      // Quiz finished, show results
      navigateToResults();
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      _persistCurrentAnswer(requireAnswer: false);
      setState(() {
        currentQuestionIndex--;
        _syncControllersWithCurrentQuestion();
      });
    }
  }

  void navigateToResults() {
    int correctCount = 0;
    for (var question in questions) {
      if (_isIdentification(question)) {
        final correctText =
            question.options.isNotEmpty ? question.options.first : '';
        final userText = userAnswers[question.id] as String?;
        if (userText != null &&
            _normalizeAnswer(userText) == _normalizeAnswer(correctText)) {
          correctCount++;
        }
      } else {
        final selected = userAnswers[question.id];
        if (selected is int && selected == question.correctIndex) {
          correctCount++;
        }
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

  String _normalizeAnswer(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Widget _buildIdentificationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Type your answer below. Spelling matters, but we ignore capital letters and extra spaces.",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.accentColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: identificationCtrl,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceColor,
            hintText: "Enter your answer here",
            prefixIcon: const Icon(Icons.edit_rounded),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
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
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Take Quiz",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.quiz_outlined,
                    size: 40,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "No questions available",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "This quiz doesn't have any questions yet",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.quizTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Question ${currentQuestionIndex + 1} of ${questions.length}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Question Text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Question ${currentQuestionIndex + 1}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentQuestion.question,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _isIdentification(currentQuestion)
                    ? _buildIdentificationInput()
                    : Column(
                        children: List.generate(
                          currentQuestion.options.length,
                          (index) {
                            final isSelected = selectedOption == index;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => selectOption(index),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : const Color(0xFFE5E7EB),
                                        width: isSelected ? 2 : 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.04),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFFE5E7EB),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF9CA3AF),
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: AppTheme.primaryColor,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            currentQuestion.options[index],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 30),
                // Navigation Buttons
                Row(
                  children: [
                    if (currentQuestionIndex > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: previousQuestion,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text(
                            "Previous",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: const BorderSide(
                              color: AppTheme.borderColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    if (currentQuestionIndex > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: currentQuestionIndex > 0 ? 1 : 1,
                      child: ElevatedButton.icon(
                        onPressed: nextQuestion,
                        icon: Icon(
                          currentQuestionIndex < questions.length - 1
                              ? Icons.arrow_forward_rounded
                              : Icons.check_rounded,
                        ),
                        label: Text(
                          currentQuestionIndex < questions.length - 1
                              ? "Next"
                              : "Finish",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

}