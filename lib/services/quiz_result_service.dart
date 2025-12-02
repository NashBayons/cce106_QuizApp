// lib/services/result_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz_app/models/quiz_result_model.dart';

class ResultService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  /// Save a quiz result
  Future<void> saveResult(QuizResultModel result) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('results')
        .add(result.toMap());
  }

  /// Get all results for a specific quiz
  Stream<QuerySnapshot> getQuizResults(String quizId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('results')
        .where('quizId', isEqualTo: quizId)
        .orderBy('completedAt', descending: true)
        .snapshots();
  }

  /// Get all results grouped by quiz
  Future<Map<String, QuizResultsSummary>> getResultsSummary() async {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('results')
          .orderBy('completedAt', descending: true) // ← Add ordering
          .get();

      Map<String, QuizResultsSummary> summaries = {};

      for (var doc in snapshot.docs) {
        final result = QuizResultModel.fromMap(doc.id, doc.data());
        
        if (!summaries.containsKey(result.quizId)) {
          // First time seeing this quiz - create new summary
          summaries[result.quizId] = QuizResultsSummary(
            quizId: result.quizId,
            quizTitle: result.quizTitle,
            attempts: [],
          );
        }
        
        // Add this attempt to the quiz's attempts list
        summaries[result.quizId]!.attempts.add(result);
      }

      // Debug: Print what we found
      print("📊 Found ${summaries.length} unique quizzes");
      summaries.forEach((quizId, summary) {
        print("   Quiz: ${summary.quizTitle} (ID: $quizId) - ${summary.attemptCount} attempts");
      });

      return summaries;
    }

  /// Get a single result by ID
  Future<QuizResultModel?> getResultById(String resultId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('results')
        .doc(resultId)
        .get();

    if (!doc.exists) return null;
    return QuizResultModel.fromMap(doc.id, doc.data()!);
  }
}

class QuizResultsSummary {
  final String quizId;
  final String quizTitle;
  final List<QuizResultModel> attempts;

  QuizResultsSummary({
    required this.quizId,
    required this.quizTitle,
    required this.attempts,
  });

  int get attemptCount => attempts.length;
  
  double get averageScore {
    if (attempts.isEmpty) return 0;
    return attempts.map((a) => a.percentage).reduce((a, b) => a + b) / attempts.length;
  }

  QuizResultModel? get bestAttempt {
    if (attempts.isEmpty) return null;
    return attempts.reduce((a, b) => a.percentage > b.percentage ? a : b);
  }

  QuizResultModel? get latestAttempt {
    if (attempts.isEmpty) return null;
    return attempts.first; // Already sorted by completedAt desc
  }
}