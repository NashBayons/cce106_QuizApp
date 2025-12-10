import 'package:flutter/material.dart';
import 'package:quiz_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quiz_app/services/auth_service.dart';
import 'package:quiz_app/theme/app_theme.dart';
import 'package:quiz_app/views/adminviews/admin_dashboard.dart'; // Make sure this imports AdminDashboard
import 'package:quiz_app/views/authviews/login_page.dart';
import 'package:quiz_app/views/quizviews/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(); // Create once and reuse
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz Maker',
      theme: AppTheme.lightTheme,
      home: StreamBuilder<Map<String, dynamic>?>(
        stream: authService.userWithRoleStream,
        builder: (context, snapshot) {
          // 🔵 1. Still loading authentication state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            );
          }

          // 🔴 2. No user = go to login page
          if (!snapshot.hasData || snapshot.data == null) {
            return LoginPage();
          }

          final data = snapshot.data!;
          final user = data['user'];
          final role = data['role'] as String? ?? 'user'; // Default to 'user' if somehow null

          // 🐛 DEBUG: Print what we received
          print('🔍 User: ${user?.email}');
          print('🔍 Role: $role');
          print('🔍 Role type: ${role.runtimeType}');
          print('🔍 Is admin? ${role == "admin"}');

          // 🟢 3. User and role loaded → redirect based on role
          if (role == "admin") {
            print('✅ Redirecting to AdminDashboard');
            return const AdminDashboard(); // Changed from AdminDashboardPage
          } else if (role == "user") {
            print('✅ Redirecting to HomePage');
            return const HomePage();
          }
          else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}