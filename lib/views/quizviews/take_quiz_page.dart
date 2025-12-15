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
  Map<String, dynamic> userAnswers = {};
  int currentQuestionIndex = 0;
  bool isLoading = true;
  int? selectedOption;
  final TextEditingController identificationCtrl = TextEditingController();
  late PageController _pageController;
  final Map<int, bool> _hintVisible = {}; // Track hint visibility for each question

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    identificationCtrl.dispose();
    super.dispose();
  }



  String _getHint(QuestionModel question) {
    if (_isIdentification(question)) {
      final correctAnswer = question.options.isNotEmpty ? question.options.first : '';
      if (correctAnswer.length > 3) {
        // Show first letter and length hint
        return "Hint: Starts with '${correctAnswer[0].toUpperCase()}' and has ${correctAnswer.length} letters";
      }
      return "Hint: Type the exact answer";
    } else {
      // For multiple choice, show which option is correct by position
      final correctAnswer = question.options[question.correctIndex];
      if (correctAnswer.length > 2) {
        return "Hint: The correct answer starts with '${correctAnswer[0].toUpperCase()}'";
      }
      return "Hint: Select the correct option above";
    }
  }

  Future<void> loadQuestions() async {
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
            SnackBar(
              content: const Text("Please type your answer"),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
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
            SnackBar(
              content: const Text("Please select an answer"),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
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
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      navigateToResults();
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      _persistCurrentAnswer(requireAnswer: false);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
          quizId: widget.quizId,
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

  void _onPageChanged(int index) {
    setState(() {
      currentQuestionIndex = index;
      _syncControllersWithCurrentQuestion();
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

    if (questions.isEmpty) {
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Take Quiz",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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

    final progress = (currentQuestionIndex + 1) / questions.length;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.quizTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${currentQuestionIndex + 1} / ${questions.length}",
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
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.borderColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          // Flashcard Container
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemCount: questions.length,
              itemBuilder: (context, index) {
                return _buildFlashcard(questions[index]);
              },
            ),
          ),
          // Navigation Controls
          Container(
            padding: const EdgeInsets.all(20),
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
              children: [
                if (currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: previousQuestion,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text(
                        "Previous",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: AppTheme.borderColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: nextQuestion,
                    icon: Icon(
                      currentQuestionIndex < questions.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      size: 18,
                    ),
                    label: Text(
                      currentQuestionIndex < questions.length - 1
                          ? "Next"
                          : "Finish Quiz",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(QuestionModel question) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: _buildCardFront(question),
      ),
    );
  }

  Widget _buildCardFront(QuestionModel question) {
    final isHintVisible = _hintVisible[currentQuestionIndex] ?? false;
    
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600, minHeight: 400),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Type Badge and Flip Hint
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getQuestionTypeLabel(question.questionType),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

              ],
            ),
            const SizedBox(height: 24),
            // Question Text
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
            // Question Image
            if (question.questionImageUrl != null) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  question.questionImageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.broken_image,
                              color: AppTheme.textSecondary, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Image failed to load',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Hint Icon Button
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _hintVisible[currentQuestionIndex] = !isHintVisible;
                    });
                  },
                  icon: Icon(
                    isHintVisible ? Icons.lightbulb : Icons.lightbulb_outline,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                  tooltip: 'Show hint',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            // Hint Text (shown when icon is tapped)
            if (isHintVisible) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getHint(question),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Answer Options
            _isIdentification(question)
                ? _buildIdentificationInput()
                : _buildMultipleChoiceOptions(question),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(QuestionModel question) {
    final correctAnswer = _isIdentification(question)
        ? (question.options.isNotEmpty ? question.options.first : 'N/A')
        : question.options[question.correctIndex];
    
    return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600, minHeight: 400),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Answer Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'CORRECT ANSWER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Correct Answer
            Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              correctAnswer,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Flip Hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flip_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Tap to flip back',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildMultipleChoiceOptions(QuestionModel question) {
    return Column(
      children: List.generate(
        question.options.length,
        (index) {
          final isSelected = selectedOption == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => selectOption(index),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.borderColor,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Option Image
                            if (question.optionImageUrls != null &&
                                index < question.optionImageUrls!.length &&
                                question.optionImageUrls![index] != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  question.optionImageUrls![index]!,
                                  width: double.infinity,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.broken_image,
                                          color: AppTheme.textSecondary),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Option Text
                            Text(
                              question.options[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: AppTheme.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
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
    );
  }

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
                  "Type your answer below",
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
            fillColor: AppTheme.backgroundColor,
            hintText: "Enter your answer",
            prefixIcon: const Icon(Icons.edit_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'MULTIPLE CHOICE';
      case 'true_false':
        return 'TRUE OR FALSE';
      case 'identification':
        return 'IDENTIFICATION';
      default:
        return 'QUESTION';
    }
  }
}
