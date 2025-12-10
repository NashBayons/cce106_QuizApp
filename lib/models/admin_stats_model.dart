// lib/models/admin_stats_model.dart

class AdminStatsModel {
  final int totalUsers;
  final int totalQuizzes;
  final int totalQuestions;
  final int totalResults;
  final Map<String, int> questionTypeCounts; // Changed from quizTypeCounts
  final int adminCount;
  final int regularUserCount;
  final int activeUsers;
  final double averageScore;
  final List<RecentActivityModel> recentAttempts;
  final List<RecentActivityModel> recentQuizzes;

  AdminStatsModel({
    required this.totalUsers,
    required this.totalQuizzes,
    required this.totalQuestions,
    required this.totalResults,
    required this.questionTypeCounts, // Changed from quizTypeCounts
    required this.adminCount,
    required this.regularUserCount,
    required this.activeUsers,
    required this.averageScore,
    required this.recentAttempts,
    required this.recentQuizzes,
  });

  // Helper getters
  double get userEngagementPercentage {
    if (totalUsers == 0) return 0;
    return (activeUsers / totalUsers) * 100;
  }

  List<RecentActivityModel> get allRecentActivities {
    final combined = [...recentAttempts, ...recentQuizzes];
    combined.sort((a, b) => b.time.compareTo(a.time));
    return combined;
  }
}

class RecentActivityModel {
  final String title;
  final String subtitle;
  final DateTime time;
  final ActivityType type;
  final double? score; // For quiz attempts

  RecentActivityModel({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    this.score,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

enum ActivityType {
  quizAttempt,
  quizCreated,
  userRegistered,
}
