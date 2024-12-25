import 'package:firebase_auth/firebase_auth.dart';

class LocalUser {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String email;
  final bool isAdmin;

  LocalUser({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.email,
    required this.isAdmin,
  });

  factory LocalUser.fromFirebase(
      User firebaseUser, Map<String, dynamic> additionalData) {
    return LocalUser(
      id: firebaseUser.uid,
      fullName: additionalData['fullName'] ?? '',
      phoneNumber: additionalData['phoneNumber'] ?? '',
      address: additionalData['address'] ?? '',
      email: firebaseUser.email ?? 'No email',
      isAdmin: (additionalData['role'] ?? 'user') == 'admin',
    );
  }

  // CopyWith method to create a new instance with updated values
  LocalUser copyWith({
    String? fullName,
    String? phoneNumber,
    String? address,
  }) {
    return LocalUser(
      id: id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      email: email,
      isAdmin: isAdmin,
    );
  }
}
