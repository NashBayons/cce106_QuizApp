import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  /// Create quiz
  Future<String?> addQuiz(String title, String desc) async {
    final docRef = await _db
        .collection("users")
        .doc(userId)
        .collection("quizzes")
        .add({
      "title": title,
      "description": desc,
      "ownerId": userId,
      "createdAt": DateTime.now().toIso8601String(),
    });
    return docRef.id;
  }

  Stream<QuerySnapshot> getQuizzes() {
    final userId = _auth.currentUser!.uid;

    return _db
      .collection("users")
      .doc(userId)
      .collection("quizzes")
      .orderBy("createdAt", descending: true)
      .snapshots();
  }


  /// Update quiz
  Future<void> updateQuiz(String id, Map<String, dynamic> data) async {
    final userId = _auth.currentUser!.uid;

    await _db
        .collection("users")
        .doc(userId)
        .collection("quizzes")
        .doc(id)
        .update(data);
  }

  /// Delete quiz
  Future<void> deleteQuiz(String id) async {
    final userId = _auth.currentUser!.uid;

    await _db
        .collection("users")
        .doc(userId)
        .collection("quizzes")
        .doc(id)
        .delete();
  }

  /// Stream all quizzes of the logged-in user
  Stream<QuerySnapshot> getUserQuizzes() {
    return _db
        .collection("users")
        .doc(userId)
        .collection("quizzes")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  
}
