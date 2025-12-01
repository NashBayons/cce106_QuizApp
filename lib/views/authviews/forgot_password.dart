import 'package:flutter/material.dart';
import 'package:quiz_app/services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final AuthService auth = AuthService();
  final TextEditingController emailCtrl = TextEditingController();
  bool loading = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password")),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  errorText: errorMessage.isNotEmpty ? errorMessage : null, // Show error message if any
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                child: loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Reset Password"),
                onPressed: () async {
                  if (emailCtrl.text.isEmpty) {
                    setState(() {
                      errorMessage = "Please enter your email address."; 
                    });
                    return;
                  }
                  setState(() {
                    loading = true;
                    errorMessage = ''; 
                  });

                  bool success = await auth.ResetPassword(emailCtrl.text.trim());

                  setState(() {
                    loading = false;
                  });

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Password reset email sent! Please check your inbox.")),
                    );
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      errorMessage = "Failed to send reset email. Please try again."; 
                    });
                  }
                },
              ),
              SizedBox(height: 12),
              TextButton(
                child: Text("Back to Login"),
                onPressed: () {
                  Navigator.pop(context); 
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}