// lib/services/admin_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/models/admin_stats_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch comprehensive admin statistics
  /// [startDate] - Optional start date for filtering data. If null, fetches all data.
  /// [endDate] - Optional end date for filtering data. If null, no upper bound.
  Future<AdminStatsModel> getAdminStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      // Fetch all collections
      final users = await _firestore.collection("users").get();
      
      // Fetch all quizzes (we'll filter client-side to avoid index requirements)
      final allQuizzes = await _firestore.collectionGroup("quizzes").get();
      
      // Filter quizzes by date range if specified
      final quizzes = allQuizzes.docs.where((doc) {
        if (startDate == null && endDate == null) return true;
        
        final data = doc.data() as Map<String, dynamic>;
        final createdAtStr = data['createdAt'] as String?;
        if (createdAtStr == null) return false;
        
        final createdAt = DateTime.parse(createdAtStr);
        
        if (startDate != null && createdAt.isBefore(startDate)) return false;
        if (endDate != null && createdAt.isAfter(endDate)) return false;
        
        return true;
      }).toList();
      
      final questions = await _firestore.collectionGroup("questions").get();
      
      // Fetch all results (we'll filter client-side to avoid index requirements)
      final allResults = await _firestore.collectionGroup("results").get();
      
      // Filter results by date range if specified
      final results = allResults.docs.where((doc) {
        if (startDate == null && endDate == null) return true;
        
        final data = doc.data() as Map<String, dynamic>;
        final completedAtStr = data['completedAt'] as String?;
        if (completedAtStr == null) return false;
        
        final completedAt = DateTime.parse(completedAtStr);
        
        if (startDate != null && completedAt.isBefore(startDate)) return false;
        if (endDate != null && completedAt.isAfter(endDate)) return false;
        
        return true;
      }).toList();

      // Calculate QUESTION type distribution (not quiz types)
      Map<String, int> questionTypeCounts = {
        'Multiple Choice': 0,
        'True or False': 0,
        'Identification': 0,
        'Mixed': 0,
      };
      
      // Group questions by quizId to identify mixed quizzes
      Map<String, Set<String>> quizQuestionTypes = {};
      
      for (var doc in questions.docs) {
        final data = doc.data();
        final questionType = data['questionType'] as String? ?? 'multiple_choice';
        final quizId = data['quizId'] as String? ?? '';
        
        // Track question types per quiz
        if (quizId.isNotEmpty) {
          quizQuestionTypes.putIfAbsent(quizId, () => <String>{});
          quizQuestionTypes[quizId]!.add(questionType);
        }
        
        // Map storage values to display names and count question types
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

      // Count quizzes with multiple question types as "Mixed"
      int mixedQuizCount = 0;
      for (var types in quizQuestionTypes.values) {
        if (types.length > 1) {
          mixedQuizCount++;
        }
      }
      questionTypeCounts['Mixed'] = mixedQuizCount;

      // Remove types with 0 count (except Mixed which should always show)
      questionTypeCounts.removeWhere((key, value) => value == 0 && key != 'Mixed');

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
      // Extract user IDs from results and only count those that exist in users collection
      Set<String> allUserIdsFromResults = {};
      for (var doc in results) {
        // The path is: users/{userId}/results/{resultId}
        // We need to get the userId from the parent collection
        final parentRef = doc.reference.parent.parent;
        if (parentRef != null) {
          allUserIdsFromResults.add(parentRef.id);
        }
      }

      // Create a set of existing user IDs for validation
      Set<String> existingUserIds = users.docs.map((doc) => doc.id).toSet();
      
      // Only count active users that actually exist in the users collection
      Set<String> activeUserIds = allUserIdsFromResults.intersection(existingUserIds);
      
      // Ensure totalUsers is accurate and always >= activeUsers
      // Use the count of existing user IDs to ensure consistency
      final accurateTotalUsers = existingUserIds.length;
      
      // Safety check: totalUsers must be at least as large as activeUsers
      final finalTotalUsers = accurateTotalUsers < activeUserIds.length 
          ? activeUserIds.length 
          : accurateTotalUsers;
      
      // Validate and fix role distribution to match finalTotalUsers
      final calculatedRoleTotal = adminCount + regularUserCount;
      if (calculatedRoleTotal != finalTotalUsers) {
        regularUserCount = finalTotalUsers - adminCount;
      }

      // Calculate average score
      double totalScore = 0;
      int scoreCount = 0;
      for (var doc in results) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('percentage')) {
          totalScore += (data['percentage'] as num).toDouble();
          scoreCount++;
        }
      }
      double avgScore = scoreCount > 0 ? totalScore / scoreCount : 0;

      // Get recent quiz attempts (last 5)
      List<RecentActivityModel> recentAttempts = [];
      final sortedResults = results.toList()
        ..sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['completedAt'] as String?;
          final bTime = bData['completedAt'] as String?;
          if (aTime == null || bTime == null) return 0;
          return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
        });

      for (var i = 0; i < sortedResults.length && i < 5; i++) {
        final data = sortedResults[i].data() as Map<String, dynamic>;
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
      final sortedQuizzes = quizzes.toList()
        ..sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as String?;
          final bTime = bData['createdAt'] as String?;
          if (aTime == null || bTime == null) return 0;
          return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
        });

      List<RecentActivityModel> recentQuizzes = [];
      for (var i = 0; i < sortedQuizzes.length && i < 5; i++) {
        final data = sortedQuizzes[i].data() as Map<String, dynamic>;
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
        totalUsers: finalTotalUsers,
        totalQuizzes: quizzes.length,
        totalQuestions: questions.size,
        totalResults: results.length,
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
