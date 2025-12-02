// lib/models/quiz_result_model.dart
class QuizResultModel {
  final String id;
  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final double percentage;
  final DateTime completedAt;
  final Map<String, dynamic> answers; // questionId -> user's answer index

  QuizResultModel({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
    required this.completedAt,
    required this.answers,
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'percentage': percentage,
      'completedAt': completedAt.toIso8601String(),
      'answers': answers,
    };
  }

  factory QuizResultModel.fromMap(String id, Map<String, dynamic> map) {
    return QuizResultModel(
      id: id,
      quizId: map['quizId'] ?? '',
      quizTitle: map['quizTitle'] ?? '',
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      completedAt: DateTime.parse(map['completedAt']),
      answers: Map<String, dynamic>.from(map['answers'] ?? {}),
    );
  }
}