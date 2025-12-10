// lib/services/admin_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/models/admin_stats_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch comprehensive admin statistics
  Future<AdminStatsModel> getAdminStats() async {
    try {
      // Fetch all collections
      final users = await _firestore.collection("users").get();
      final quizzes = await _firestore.collectionGroup("quizzes").get();
      final questions = await _firestore.collectionGroup("questions").get();
      final results = await _firestore.collectionGroup("results").get();

      // Calculate QUESTION type distribution (not quiz types)
      Map<String, int> questionTypeCounts = {
        'Multiple Choice': 0,
        'True or False': 0,
        'Identification': 0,
      };
      
      for (var doc in questions.docs) {
        final data = doc.data();
        final questionType = data['questionType'] as String? ?? 'multiple_choice';
        
        // Map storage values to display names
        String displayName;
        switch (questionType) {
          case 'multiple_choice':
            displayName = 'Multiple Choice';
            break;
          case 'true_false':
            displayName = 'True or False';
            break;
          case 'identification':
            displayName = 'Identification';
            break;
          default:
            displayName = 'Multiple Choice';
        }
        
        questionTypeCounts[displayName] = (questionTypeCounts[displayName] ?? 0) + 1;
      }

      // Remove types with 0 count
      questionTypeCounts.removeWhere((key, value) => value == 0);

      // Calculate role distribution
      int adminCount = 0;
      int regularUserCount = 0;
      for (var doc in users.docs) {
        final data = doc.data();
        final role = data['role'] ?? 'user';
        if (role == 'admin') {
          adminCount++;
        } else {
          regularUserCount++;
        }
      }

      // Calculate active users (users who have taken quizzes)
      // FIXED: Properly extract user IDs from the document reference path
      Set<String> activeUserIds = {};
      for (var doc in results.docs) {
        // The path is: users/{userId}/results/{resultId}
        // We need to get the userId from the parent collection
        final parentRef = doc.reference.parent.parent;
        if (parentRef != null) {
          activeUserIds.add(parentRef.id);
        }
      }

      print('🔍 Debug - Total users: ${users.size}');
      print('🔍 Debug - Active users: ${activeUserIds.length}');
      print('🔍 Debug - Active user IDs: $activeUserIds');

      // Calculate average score
      double totalScore = 0;
      int scoreCount = 0;
      for (var doc in results.docs) {
        final data = doc.data();
        if (data.containsKey('percentage')) {
          totalScore += (data['percentage'] as num).toDouble();
          scoreCount++;
        }
      }
      double avgScore = scoreCount > 0 ? totalScore / scoreCount : 0;

      // Get recent quiz attempts (last 5)
      List<RecentActivityModel> recentAttempts = [];
      final sortedResults = results.docs.toList()
        ..sort((a, b) {
          final aTime = a.data()['completedAt'] as String?;
          final bTime = b.data()['completedAt'] as String?;
          if (aTime == null || bTime == null) return 0;
          return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
        });

      for (var i = 0; i < sortedResults.length && i < 5; i++) {
        final data = sortedResults[i].data();
        final percentage = (data['percentage'] ?? 0).toDouble();
        recentAttempts.add(RecentActivityModel(
          title: data['quizTitle'] ?? 'Unknown Quiz',
          subtitle: '${data['correctAnswers']}/${data['totalQuestions']} correct (${percentage.toStringAsFixed(1)}%)',
          time: data['completedAt'] != null 
              ? DateTime.parse(data['completedAt'])
              : DateTime.now(),
          type: ActivityType.quizAttempt,
          score: percentage,
        ));
      }

      // Get recently created quizzes (last 5)
      final sortedQuizzes = quizzes.docs.toList()
        ..sort((a, b) {
          final aTime = a.data()['createdAt'] as String?;
          final bTime = b.data()['createdAt'] as String?;
          if (aTime == null || bTime == null) return 0;
          return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
        });

      List<RecentActivityModel> recentQuizzes = [];
      for (var i = 0; i < sortedQuizzes.length && i < 5; i++) {
        final data = sortedQuizzes[i].data();
        recentQuizzes.add(RecentActivityModel(
          title: data['title'] ?? 'Untitled Quiz',
          subtitle: data['description'] ?? 'No description',
          time: data['createdAt'] != null 
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
          type: ActivityType.quizCreated,
        ));
      }

      return AdminStatsModel(
        totalUsers: users.size,
        totalQuizzes: quizzes.size,
        totalQuestions: questions.size,
        totalResults: results.size,
        questionTypeCounts: questionTypeCounts,
        adminCount: adminCount,
        regularUserCount: regularUserCount,
        activeUsers: activeUserIds.length,
        averageScore: avgScore,
        recentAttempts: recentAttempts,
        recentQuizzes: recentQuizzes,
      );
    } catch (e) {
      print('Error fetching admin stats: $e');
      rethrow;
    }
  }

  /// Get color based on score percentage
  Color getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  /// Get icon and color for activity type
  Map<String, dynamic> getActivityIconAndColor(ActivityType type, {double? score}) {
    switch (type) {
      case ActivityType.quizAttempt:
        return {
          'icon': Icons.quiz,
          'color': score != null ? getScoreColor(score) : Colors.blue,
        };
      case ActivityType.quizCreated:
        return {
          'icon': Icons.add_circle,
          'color': Colors.purple,
        };
      case ActivityType.userRegistered:
        return {
          'icon': Icons.person_add,
          'color': Colors.green,
        };
    }
  }
}
