import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowers_shop_mvp/screens/authentication/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController.clear();
    _passwordController.clear();
  }

  /// Handle user login and save token and role.
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final navigator = Navigator.of(context);

      try {
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Fetch user role from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          final role = userDoc.data()?['role'];
          final token = await credential.user!.getIdToken();

          if (role != null && token != null) {
            // Save token and role
            await saveLoginStatus(token, role);

            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (context) => DashboardScreen(isAdmin: role == 'admin'),
              ),
            );
          } else {
            _showErrorDialog('User role not found. Please contact support.');
          }
        } else {
          _showErrorDialog('User data not found. Please contact support.');
        }
      } on FirebaseAuthException catch (e) {
        _showErrorDialog(_getFriendlyErrorMessage(e.code));
      } catch (e) {
        _showErrorDialog('An unexpected error occurred. Please try again.');
      }
    }
  }

  /// Save login token and role in shared preferences.
  Future<void> saveLoginStatus(String token, String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userToken', token);
    await prefs.setString('userRole', role);
    print('Token and role saved successfully: $token, $role');
  }

  String _getFriendlyErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-credential':
        return 'Invalid email or password, Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required.';
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.all(0.0),
                // Add padding around the button
                child: SizedBox(
                  width: double.infinity, // Full width
                  height: 60, // Fixed height
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8.0), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  // Navigate to Register Screen
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                  );

                  // Clear fields if user successfully registered
                  if (result == true) {
                    _emailController.clear();
                    _passwordController.clear();
                  }
                },
                child: const Text('Don\'t have an account? Register Here',
                    style: TextStyle(color: Colors.black54, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
