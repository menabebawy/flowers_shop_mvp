import 'package:firebase_auth/firebase_auth.dart';

class LocalUser {
  final String id;
  final String email;
  final bool isAdmin;

  LocalUser({
    required this.id,
    required this.email,
    required this.isAdmin,
  });

  factory LocalUser.fromFirebase(
      User firebaseUser, Map<String, dynamic> additionalData) {
    return LocalUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? 'No email',
      isAdmin: (additionalData['role'] ?? 'user') == 'admin',
    );
  }
}
