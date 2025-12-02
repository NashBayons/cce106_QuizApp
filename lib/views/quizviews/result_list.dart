// lib/views/results/results_list_page.dart
import 'package:flutter/material.dart';
import 'package:quiz_app/services/quiz_result_service.dart';
import 'package:quiz_app/views/quizviews/quiz_attemp.dart';

class ResultsListPage extends StatefulWidget {
  const ResultsListPage({super.key});

  @override
  State<ResultsListPage> createState() => _ResultsListPageState();
}

class _ResultsListPageState extends State<ResultsListPage> {
  final ResultService resultService = ResultService();
  Map<String, QuizResultsSummary>? summaries;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  Future<void> loadResults() async {
    final data = await resultService.getResultsSummary();
    setState(() {
      summaries = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Results"),
        backgroundColor: const Color(0xff9d8eff),
      ),
      backgroundColor: const Color(0xffdcd6ff),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : summaries == null || summaries!.isEmpty
              ? const Center(
                  child: Text(
                    "No quiz results yet.\nTake some quizzes to see results!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadResults,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: summaries!.length,
                    itemBuilder: (context, index) {
                      final summary = summaries!.values.elementAt(index);
                      final avgScore = summary.averageScore;
                      final color = _getScoreColor(avgScore);

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizAttemptsPage(
                                  summary: summary,
                                ),
                              ),
                            ).then((_) => loadResults()); // Refresh on return
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        summary.quizTitle,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: color),
                                      ),
                                      child: Text(
                                        "${avgScore.toStringAsFixed(0)}%",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    _buildStatCard(
                                      icon: Icons.repeat,
                                      label: "Attempts",
                                      value: "${summary.attemptCount}",
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    _buildStatCard(
                                      icon: Icons.emoji_events,
                                      label: "Best Score",
                                      value: "${summary.bestAttempt?.percentage.toStringAsFixed(0)}%",
                                      color: Colors.amber,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Tap to view all attempts",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }
}