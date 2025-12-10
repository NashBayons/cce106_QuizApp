import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  Future<void> _createUserDocIfNotExists(User user, {String defaultRole = 'user'}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    
    try {
      final doc = await docRef.get();
      
      if (!doc.exists) {
        // Document doesn't exist - create it
        print('📝 Creating new user document for ${user.email}');
        await docRef.set({
          'email': user.email,
          'displayName': user.displayName ?? '',
          'role': defaultRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Document exists - check if it has a role field
        final data = doc.data();
        if (data == null || !data.containsKey('role')) {
          print('🔧 Adding role field to existing user ${user.email}');
          // Only update if role is missing - don't overwrite existing role!
          await docRef.update({
            'role': defaultRole,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          print('✅ User ${user.email} already has role: ${data['role']}');
          // Don't do anything - role already exists!
        }
      }
    } catch (e) {
      print('Error in _createUserDocIfNotExists: $e');
    }
  }

  /// Read role once. Returns 'user' if missing or null.
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return 'user';
      final data = doc.data();
      return data != null && data.containsKey('role') ? data['role'] as String : 'user';
    } catch (e) {
      print('getUserRole error: $e');
      return 'user'; // Default to user role on error
    }
  }

  /// Promote a user to admin (or set any role). Returns true on success.
  Future<bool> promoteToAdmin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('promoteToAdmin error: $e');
      return false;
    }
  }

  /// Generic setter if you want to set arbitrary role
  Future<bool> setUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('setUserRole error: $e');
      return false;
    }
  }

  // ---------- Sign in / Register flows ----------
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user != null) await _createUserDocIfNotExists(user);
        return user;
      } else {
        final googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) await _createUserDocIfNotExists(user);
        return user;
      }
    } catch (e) {
      print('Google signIn error: $e');
      return null;
    }
  }

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await _createUserDocIfNotExists(user);
      }
      return user;
    } catch (e) {
      print("Registration error: $e");
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final user = userCredential.user;
      if (user != null) {
        await _createUserDocIfNotExists(user);
      }
      return user;
    } catch (e) {
      print("Login error: $e");
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

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn?.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('signOut error: $e');
    }
  }

  // ---------- Streams ----------
  /// Simple auth state stream (keeps your existing behavior)
  Stream<User?> get userStream => _auth.authStateChanges();

  /// Stream that yields combined { "user": User?, "role": String } whenever auth state or role changes.
  /// Now defaults to 'user' role if missing.
  Stream<Map<String, dynamic>?> get userWithRoleStream {
    return _auth.authStateChanges().asyncExpand((firebaseUser) async* {
      if (firebaseUser == null) {
        print('🔍 Auth stream: No user signed in');
        yield null;
        return;
      }

      print('🔍 Auth stream: User signed in - ${firebaseUser.email}');

      // Ensure the user document exists before listening to it
      await _createUserDocIfNotExists(firebaseUser);

      // Now listen to the user's doc and forward updates
      yield* _firestore.collection('users').doc(firebaseUser.uid).snapshots().map((snap) {
        print('🔍 Firestore snapshot received for ${firebaseUser.uid}');
        print('🔍 Document exists: ${snap.exists}');
        
        if (snap.exists) {
          final data = snap.data();
          print('🔍 Document data: $data');
          print('🔍 Has role key: ${data?.containsKey('role')}');
          
          final role = data != null && data.containsKey('role') 
              ? data['role'] as String 
              : 'user';
          
          print('🔍 Final role from Firestore: $role');
          return {'user': firebaseUser, 'role': role};
        } else {
          print('⚠️ Document does not exist, yielding user role');
          return {'user': firebaseUser, 'role': 'user'};
        }
      });
    });
  }
}