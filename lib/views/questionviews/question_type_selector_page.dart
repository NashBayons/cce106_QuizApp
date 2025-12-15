import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_type.dart';
import 'package:quiz_app/theme/app_theme.dart';
import 'package:quiz_app/views/questionviews/addquestion_page.dart';
import 'package:quiz_app/views/questionviews/question_summary_page.dart';

class QuestionTypeSelectorPage extends StatelessWidget {
  final String quizId;

  const QuestionTypeSelectorPage({
    super.key,
    required this.quizId,
  });

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuestionSummaryPage(quizId: quizId),
                  ),
                );
              },
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a quiz type',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pick the format that matches the kind of question you want to create. '
                'Each type includes friendly instructions to guide you.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ...QuestionType.values.map(
                (type) => _TypeCard(
                  icon: type.icon,
                  title: type.label,
                  description: type.description,
                  accentColor: _typeColor(type),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddQuestionPage(
                          quizId: quizId,
                          initialType: type,
                        ),
                      ),
                    );
                  },
                ),
              ),
              _TypeCard(
                icon: Icons.auto_awesome,
                title: 'Mixed Quiz',
                description:
                    'Switch between Multiple Choice, True/False, and Identification inside the question builder.',
                accentColor: AppTheme.secondaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddQuestionPage(
                        quizId: quizId,
                        allowTypeSwitch: true,
                        initialType: QuestionType.multipleChoice,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _typeColor(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return AppTheme.primaryColor;
      case QuestionType.trueFalse:
        return AppTheme.accentColor;
      case QuestionType.identification:
        return AppTheme.secondaryColor;
    }
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

