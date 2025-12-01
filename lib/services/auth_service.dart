import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  Future<User?> signInWithGoogle() async{
    if(kIsWeb){
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential =
        await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
    } else {
      final googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return(await _auth.signInWithCredential(credential)).user;
    }

  }

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword
      (email: email, 
      password: password
      );
      return userCredential.user;
    } catch (e) {
      print("Registration error: $e");
      return null;
    }
  }

  Future<bool> ResetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true; 
    } catch (e) {
      print("Error sending reset email: $e");
      return false;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
      return UserCredential.user;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    if(!kIsWeb) {
      await _googleSignIn?.signOut();
    }
    await _auth.signOut();
  }
 
  Stream<User?> get userStream => _auth.authStateChanges();
}