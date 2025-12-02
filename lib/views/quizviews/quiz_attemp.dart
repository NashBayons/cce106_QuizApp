// lib/views/results/quiz_attempts_page.dart
import 'package:flutter/material.dart';
import 'package:quiz_app/services/quiz_result_service.dart';
import 'package:quiz_app/views/quizviews/attempt_detail.dart';
import 'package:intl/intl.dart';

class QuizAttemptsPage extends StatelessWidget {
  final QuizResultsSummary summary;

  const QuizAttemptsPage({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final attempts = summary.attempts;

    return Scaffold(
      appBar: AppBar(
        title: Text(summary.quizTitle),
        backgroundColor: const Color(0xff9d8eff),
      ),
      backgroundColor: const Color(0xffdcd6ff),
      body: Column(
        children: [
          // Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(15),
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
            child: Column(
              children: [
                const Text(
                  "Overall Statistics",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      "Total Attempts",
                      "${summary.attemptCount}",
                      Icons.repeat,
                      Colors.blue,
                    ),
                    _buildStat(
                      "Average Score",
                      "${summary.averageScore.toStringAsFixed(1)}%",
                      Icons.analytics,
                      Colors.purple,
                    ),
                    _buildStat(
                      "Best Score",
                      "${summary.bestAttempt?.percentage.toStringAsFixed(0)}%",
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Attempts List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: attempts.length,
              itemBuilder: (context, index) {
                final attempt = attempts[index];
                final color = _getScoreColor(attempt.percentage);
                final dateStr = DateFormat('MMM dd, yyyy - hh:mm a')
                    .format(attempt.completedAt);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttemptDetailPage(
                            resultId: attempt.id,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          // Attempt Number Badge
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xff9d8eff).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "#${attempts.length - index}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff9d8eff),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Attempt Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${attempt.correctAnswers}/${attempt.totalQuestions} correct",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Score Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color, width: 2),
                            ),
                            child: Text(
                              "${attempt.percentage.toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }
}