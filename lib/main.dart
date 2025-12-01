import 'package:flutter/material.dart';
import 'package:quiz_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quiz_app/services/auth_service.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Quiz Maker',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: StreamBuilder(
        stream: AuthService().userStream, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return HomePage();
          } else {
            return LoginPage();
          }
        }),
    );
  }
}
