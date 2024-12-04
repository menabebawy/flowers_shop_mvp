import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'authentication/login_screen.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<void> _checkUser(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        print('User is logged in: ${user.email}');

        // Fetch role from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final role = userDoc.data()?['role'];
          print('User role: $role');

          if (role == 'admin') {
            // Navigate to Admin Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(isAdmin: true),
              ),
            );
          } else if (role == 'user') {
            // Navigate to User Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(isAdmin: false),
              ),
            );
          } else {
            print('Unknown role: $role');
            // Role not recognized, navigate to login screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } else {
          print('User document does not exist in Firestore');
          // User data not found, navigate to login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        print('No user is logged in');
        // User is not logged in, navigate to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error checking user: $e');
      // Handle errors gracefully and navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check authentication after a slight delay (optional for splash effect)
    Future.delayed(Duration.zero, () => _checkUser(context));

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Show a loading indicator
      ),
    );
  }
}
