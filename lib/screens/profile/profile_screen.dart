import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/local_user.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final LocalUser? user;
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Information Section
            _buildSectionTitle('User Information'),
            _buildInfoRow('Email', user?.email),
            _buildInfoRow('Full Name', user?.fullName),
            _buildInfoRow('Phone', user?.phoneNumber),

            const SizedBox(height: 32),

            // Settings Section
            _buildSectionTitle('Settings'),
            _buildListRow(
              context,
              icon: Icons.person,
              title: 'Edit Profile',
              showArrow: true, // Show arrow only for this row
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: user),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Account Management Section
            _buildSectionTitle('Account Management'),
            _buildListRow(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                final shouldLogout = await _showConfirmationDialog(
                  context,
                  'Logout',
                  'Are you sure you want to log out?',
                );
                if (shouldLogout) {
                  try {
                    await FirebaseAuth.instance.signOut();
                    onLogout();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error logging out: $e'),
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
              title: 'Delete Account',
              titleColor: Colors.redAccent,
              onTap: () async {
                final shouldDelete = await _showConfirmationDialog(
                  context,
                  'Delete Account',
                  'Are you sure you want to delete your account? This action cannot be undone.',
                );
                if (shouldDelete) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Account deletion feature not implemented.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6),
      margin: const EdgeInsets.only(bottom: 8.0),
      //color: Colors.grey[800], // Gray background
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800], // White text
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white, // White background for row
        borderRadius: BorderRadius.circular(8.0), // Rounded corners
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
            value ?? 'Not provided',
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
    bool showArrow = false, // Default is no arrow
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white, // White background for row
        borderRadius: BorderRadius.circular(8.0), // Rounded corners
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
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        )) ??
        false;
  }
}
