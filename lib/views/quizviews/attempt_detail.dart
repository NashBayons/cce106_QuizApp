// lib/views/results/attempt_detail_page.dart
import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/models/quiz_result_model.dart';
import 'package:quiz_app/services/question_service.dart';
import 'package:quiz_app/services/quiz_result_service.dart';
import 'package:quiz_app/theme/app_theme.dart';
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
  int currentPage = 0;
  final int itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    result = await resultService.getResultById(widget.resultId);
    
    if (result != null) {
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
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (result == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Quiz Results",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        body: _buildErrorState(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Quiz Results",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildScoreCard(),
                  _buildAnswerReviewSection(),
                ],
              ),
            ),
          ),
          if (questions.length > itemsPerPage) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Result Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The quiz result you\'re looking for\ncould not be found',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final scoreColor = _getScoreColor(result!.percentage);
    final grade = _getGrade(result!.percentage);
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(result!.completedAt);

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  result!.quizTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFFF3F4F6),
          ),

          // Score Display
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Large Score Circle
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${result!.percentage.toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Grade: $grade",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Score Breakdown
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.accentColor,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${result!.correctAnswers} out of ${result!.totalQuestions} Correct",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerReviewSection() {
    final totalPages = (questions.length / itemsPerPage).ceil();
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, questions.length);
    final paginatedQuestions = questions.sublist(startIndex, endIndex);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.quiz_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Answer Review",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${questions.length} Questions",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Questions List
          ...paginatedQuestions.asMap().entries.map((entry) {
            final listIndex = entry.key;
            final actualIndex = startIndex + listIndex;
            final question = entry.value;
            return _buildQuestionCard(question, actualIndex);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, int index) {
    final userAnswer = result!.answers[question.id];
    final isIdentification = question.questionType == 'identification';
    
    bool isCorrect;
    String userAnswerText;
    String correctAnswerText;
    
    if (isIdentification) {
      final correctText = question.options.isNotEmpty ? question.options.first : '';
      final userText = userAnswer is String ? userAnswer : '';
      isCorrect = _normalizeAnswer(userText) == _normalizeAnswer(correctText);
      userAnswerText = userText.isEmpty ? 'No answer' : userText;
      correctAnswerText = correctText;
    } else {
      final userAnswerIndex = userAnswer is int ? userAnswer : null;
      isCorrect = userAnswerIndex != null && userAnswerIndex == question.correctIndex;
      userAnswerText = userAnswerIndex != null && userAnswerIndex < question.options.length
          ? question.options[userAnswerIndex]
          : 'No answer';
      correctAnswerText = question.options.isNotEmpty && question.correctIndex < question.options.length
          ? question.options[question.correctIndex]
          : '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect 
              ? AppTheme.accentColor.withOpacity(0.3)
              : AppTheme.errorColor.withOpacity(0.3),
          width: 2,
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
          // Question Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isCorrect 
                  ? AppTheme.accentColor.withOpacity(0.08)
                  : AppTheme.errorColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCorrect ? AppTheme.accentColor : AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      isCorrect 
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Question ${index + 1}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCorrect ? AppTheme.accentColor : AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Answers Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Your Answer
                _buildAnswerBox(
                  label: "Your Answer",
                  answer: userAnswerText,
                  icon: Icons.person,
                  isCorrect: isCorrect,
                  isUserAnswer: true,
                ),

                // Correct Answer (only show if wrong)
                if (!isCorrect && correctAnswerText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildAnswerBox(
                    label: "Correct Answer",
                    answer: correctAnswerText,
                    icon: Icons.lightbulb,
                    isCorrect: true,
                    isUserAnswer: false,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerBox({
    required String label,
    required String answer,
    required IconData icon,
    required bool isCorrect,
    required bool isUserAnswer,
  }) {
    final color = isUserAnswer 
        ? (isCorrect ? AppTheme.accentColor : AppTheme.errorColor)
        : AppTheme.accentColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (questions.length / itemsPerPage).ceil();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${currentPage + 1} of $totalPages',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              _buildPaginationButton(
                icon: Icons.chevron_left,
                enabled: currentPage > 0,
                onPressed: () {
                  if (currentPage > 0) {
                    setState(() {
                      currentPage--;
                    });
                  }
                },
              ),
              const SizedBox(width: 12),
              _buildPaginationButton(
                icon: Icons.chevron_right,
                enabled: currentPage < totalPages - 1,
                onPressed: () {
                  if (currentPage < totalPages - 1) {
                    setState(() {
                      currentPage++;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: enabled ? AppTheme.primaryColor : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.grey.shade400,
            size: 24,
          ),
        ),
      ),
    );
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return "A";
    if (percentage >= 80) return "B";
    if (percentage >= 70) return "C";
    if (percentage >= 60) return "D";
    return "F";
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return const Color(0xFF10B981);
    if (percentage >= 80) return const Color(0xFF84CC16);
    if (percentage >= 70) return const Color(0xFFF59E0B);
    if (percentage >= 60) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  String _normalizeAnswer(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}