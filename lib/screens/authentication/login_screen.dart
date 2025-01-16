import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowers_shop_mvp/screens/authentication/register_screen.dart';
import 'package:flowers_shop_mvp/screens/authentication/reset_password_screen.dart';
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
                builder: (context) => const DashboardScreen(),
              ),
            );
          } else {
            _showErrorDialog(
                'Benutzerrolle nicht gefunden. Bitte wenden Sie sich an den Support.');
          }
        } else {
          _showErrorDialog(
              'Benutzerdaten nicht gefunden. Bitte wenden Sie sich an den Support.');
        }
      } on FirebaseAuthException catch (e) {
        _showErrorDialog(_getFriendlyErrorMessage(e.code));
      } catch (e) {
        _showErrorDialog(
            'Ein unerwarteter Fehler ist aufgetreten. Bitte versuchen Sie es erneut.');
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
        return 'Ungültige E-Mail oder Passwort. Bitte versuchen Sie es erneut.';
      default:
        return 'Es ist ein Fehler aufgetreten. Bitte versuchen Sie es erneut.';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anmeldung fehlgeschlagen'),
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
          title: const Text('Anmelden')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-Mail'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-Mail ist erforderlich.';
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Geben Sie eine gültige E-Mail-Adresse ein..';
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
                    return 'Passwort ist erforderlich.';
                  }
                  if (value.length < 6) {
                    return 'Das Passwort muss mindestens 6 Zeichen lang sein.';
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
                      'Anmelden',
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
                child: const Text(
                    'Haben Sie kein Konto? Registrieren Sie sich hier',
                    style: TextStyle(color: Colors.black54, fontSize: 16)),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to Reset Password Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ResetPasswordScreen()),
                  );
                },
                child: const Text('Passwort vergessen?',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
