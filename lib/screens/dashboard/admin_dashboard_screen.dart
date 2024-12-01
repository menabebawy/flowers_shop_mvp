import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/product_card.dart';
import '../admin/add_product_screen.dart';
import '../admin/edit_product_screen.dart';
import '../authentication/login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final bool isAdmin;

  const AdminDashboardScreen({super.key, required this.isAdmin});

  Future<void> _logout(BuildContext context) async {
    try {
      // Store the Navigator action in a synchronous closure
      final navigator = Navigator.of(context);

      await FirebaseAuth.instance.signOut();

      // Use the stored Navigator to navigate
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Dashboard' : 'User Dashboard'),
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddProductScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logout(context),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logout(context),
                ),
              ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product.data() as Map<String, dynamic>,
                onEdit: isAdmin
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProductScreen(
                              productId: product.id,
                              productData:
                                  product.data() as Map<String, dynamic>,
                            ),
                          ),
                        );
                      }
                    : null,
                // Disable edit for non-admin users
                onDelete: isAdmin
                    ? () {
                        FirebaseFirestore.instance
                            .collection('products')
                            .doc(product.id)
                            .delete();
                      }
                    : null,
                isAdmin: isAdmin, // Disable delete for non-admin users
              );
            },
          );
        },
      ),
    );
  }
}
