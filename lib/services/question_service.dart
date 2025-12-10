// lib/services/question_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question_model.dart';
import 'package:flutter/material.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class PickedImage{
  final File file;
  final String url;
  PickedImage({required this.file, required this.url});
}

class QuestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // final CloudinaryPublic _cloudinary = CloudinaryPublic(
  //   'do5oq5ntc', 'quiz_maker'
  //   cache:false,
  // );

  String get userId => _auth.currentUser!.uid;

  /// Add question under users/{userId}/quizzes/{quizId}/questions
  Future<void> addQuestion(String quizId, QuestionModel q) async {
      print("🔍 Adding question to:");
      print("   users/${userId}/quizzes/${quizId}/questions");
    await _db
        .collection('users')
        .doc(userId)
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .add(q.toMap());
  }

  /// Stream of QuerySnapshot (raw). Use this if you want to access doc.id directly.
  Stream<QuerySnapshot> getQuestionsRaw(String quizId) {
      print("🔍 Looking for questions at:");
      print("   users/${userId}/quizzes/${quizId}/questions");
    return _db
        .collection('users')
        .doc(userId)
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        // .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Stream converted to List<QuestionModel>
  Stream<List<QuestionModel>> getQuestions(String quizId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuestionModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Update question (partial or full)
  Future<void> updateQuestion(
      String quizId, String questionId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .doc(questionId)
        .update(data);
  }

  /// Delete question
  Future<void> deleteQuestion(String quizId, String questionId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .doc(questionId)
        .delete();
  }
}