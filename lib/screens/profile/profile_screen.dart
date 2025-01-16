import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/local_user.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<LocalUser?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUser();
  }

  Future<LocalUser?> _fetchUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      return null;
    }

    final additionalData = userDoc.data() ?? {};
    return LocalUser.fromFirebase(user, additionalData);
  }

  void _refreshUser() {
    setState(() {
      _userFuture = _fetchUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Profil'),
      ),
      body: FutureBuilder<LocalUser?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Fehler beim Laden des Benutzers: ${snapshot.error}'),
            );
          }

          final user = snapshot.data;

          if (user == null) {
            FirebaseAuth.instance.signOut();
            widget.onLogout();

            return const Center(
              child: Text('Benutzerdaten nicht gefunden'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Information Section
                _buildSectionTitle('Benutzerinformationen'),
                _buildInfoRow('E-Mail', user.email),
                _buildInfoRow('Vollständiger Name', user.fullName),
                _buildInfoRow('Telefon', user.phoneNumber),
                const SizedBox(height: 32),

                // Settings Section
                _buildSectionTitle('Einstellungen'),
                _buildListRow(
                  context,
                  icon: Icons.person,
                  title: 'Profil bearbeiten',
                  showArrow: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: user),
                      ),
                    ).then((_) {
                      // Refresh user data when EditProfileScreen pops
                      _refreshUser();
                    });
                  },
                ),

                const SizedBox(height: 32),

                // Account Management Section
                _buildSectionTitle('Kontoverwaltung'),
                _buildListRow(
                  context,
                  icon: Icons.logout,
                  title: 'Abmelden',
                  onTap: () async {
                    final shouldLogout = await _showConfirmationDialog(
                      context,
                      'Abmelden',
                      'Sind Sie sicher, dass Sie sich abmelden möchten?',
                    );
                    if (shouldLogout) {
                      try {
                        await FirebaseAuth.instance.signOut();
                        widget.onLogout();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fehler beim Abmelden: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                _buildListRow(
                  context,
                  icon: Icons.delete,
                  title: 'Konto löschen',
                  titleColor: Colors.redAccent,
                  onTap: () async {
                    final shouldDelete = await _showConfirmationDialog(
                      context,
                      'Konto löschen',
                      'Sind Sie sicher, dass Sie Ihr Konto löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.',
                    );

                    if (shouldDelete) {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user != null) {
                        try {
                          // Delete user document from Firestore
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .delete();

                          // Delete user from Firebase Authentication
                          await user.delete();

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Ihr Konto wurde erfolgreich gelöscht.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Wait for 2 seconds and then log out
                          Future.delayed(const Duration(seconds: 2), () {
                            // Call your logout function here
                            widget.onLogout();
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Fehler beim Löschen des Kontos: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Kein Benutzer ist derzeit angemeldet.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value ?? 'Nicht angegeben',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
    bool showArrow = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: titleColor ?? Colors.blue),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: titleColor ?? Colors.black,
          ),
        ),
        trailing:
            showArrow ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
        onTap: onTap,
      ),
    );
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String title, String content) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Bestätigen'),
              ),
            ],
          ),
        )) ??
        false;
  }
}
