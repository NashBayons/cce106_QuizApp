// lib/views/quizviews/quiz_review_page.dart
import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/services/question_service.dart';
import 'package:quiz_app/theme/app_theme.dart';

class QuizReviewPage extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizReviewPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<QuizReviewPage> createState() => _QuizReviewPageState();
}

class _QuizReviewPageState extends State<QuizReviewPage> with SingleTickerProviderStateMixin {
  final QuestionService questionService = QuestionService();
  
  List<QuestionModel> questions = [];
  int currentQuestionIndex = 0;
  bool isLoading = true;
  late PageController _pageController;
  late AnimationController _flipController;
  final Map<int, bool> _flipStates = {}; // Track flip state for each question

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    setState(() {
      final currentFlipped = _flipStates[currentQuestionIndex] ?? false;
      if (currentFlipped) {
        _flipStates[currentQuestionIndex] = false;
        _flipController.reverse();
      } else {
        _flipStates[currentQuestionIndex] = true;
        _flipController.forward();
      }
    });
  }

  Future<void> loadQuestions() async {
    final snapshot = await questionService.getQuestionsRaw(widget.quizId).first;
    setState(() {
      questions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return QuestionModel.fromMap(doc.id, data);
      }).toList();
      isLoading = false;
    });
  }

  bool _isIdentification(QuestionModel question) =>
      question.questionType == 'identification';

  void _onPageChanged(int index) {
    setState(() {
      currentQuestionIndex = index;
      
      // Check if new page is flipped and sync animation
      final newFlipped = _flipStates[index] ?? false;
      if (newFlipped && _flipController.value < 0.5) {
        _flipController.value = 1.0;
      } else if (!newFlipped && _flipController.value > 0.5) {
        _flipController.reset();
      }
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
            "Review Quiz",
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.quizTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Review Mode",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
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
                      "Card ${currentQuestionIndex + 1} / ${questions.length}",
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
                        AppTheme.secondaryColor),
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
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
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
                    onPressed: () {
                      if (currentQuestionIndex < questions.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(
                      currentQuestionIndex < questions.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      size: 18,
                    ),
                    label: Text(
                      currentQuestionIndex < questions.length - 1
                          ? "Next"
                          : "Done",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.secondaryColor,
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
        child: GestureDetector(
          onTap: _toggleFlip,
          child: AnimatedBuilder(
            animation: _flipController,
            builder: (context, child) {
              final flipValue = _flipController.value;
              final isFlipped = flipValue > 0.5;
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Front side (shown when not flipped)
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(flipValue * 3.14159),
                    child: Opacity(
                      opacity: isFlipped ? 0.0 : 1.0,
                      child: IgnorePointer(ignoring: isFlipped, child: _buildCardFront(question)),
                    ),
                  ),
                  // Back side (shown when flipped)
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY((flipValue * 3.14159) + 3.14159),
                    child: Opacity(
                      opacity: isFlipped ? 1.0 : 0.0,
                      child: IgnorePointer(ignoring: !isFlipped, child: _buildCardBack(question)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(QuestionModel question) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600, minHeight: 400),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withOpacity(0.1),
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
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getQuestionTypeLabel(question.questionType),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flip_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to see answer',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
            const SizedBox(height: 24),
            // Study hint
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
                    Icons.school_rounded,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Think about your answer, then flip to check!",
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
              AppTheme.secondaryColor,
              AppTheme.accentColor,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryColor.withOpacity(0.3),
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
