import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/product_card.dart';
import '../admin/edit_product_screen.dart';
import '../authentication/login_screen.dart';
import '../checkout/order_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isAdmin;

  const DashboardScreen({super.key, required this.isAdmin});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? selectedCategoryId; // Selected category for filtering
  late Future<List<QueryDocumentSnapshot>> categoriesFuture;
  int pendingOrderCount = 0; // Track pending orders for the badge

  @override
  void initState() {
    super.initState();
    categoriesFuture = fetchCategories();
    _fetchPendingOrdersCount();
  }

  Future<List<QueryDocumentSnapshot>> fetchCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    return snapshot.docs;
  }

  // Fetch the count of pending orders
  Future<void> _fetchPendingOrdersCount() async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Current user ID
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    setState(() {
      pendingOrderCount = snapshot.docs.length;
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final navigator = Navigator.of(context);

      await FirebaseAuth.instance.signOut();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('isLoggedIn');
      prefs.remove('userToken');
      prefs.remove('userRole');

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
        title: Text(widget.isAdmin ? 'Admin Dashboard' : 'User Dashboard'),
        actions: [
          if (!widget.isAdmin)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrdersScreen(),
                      ),
                    );
                  },
                ),
                if (pendingOrderCount > 0)
                  Positioned(
                    right: 11,
                    top: 11,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$pendingOrderCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Dropdown
          FutureBuilder<List<QueryDocumentSnapshot>>(
            future: categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No categories available.');
              }

              final categories = snapshot.data!;

              return DropdownButton<String>(
                value: selectedCategoryId,
                hint: const Text('Filter by Category'),
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value;
                  });
                },
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...categories.map((category) {
                    final data = category.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(data['name'] ?? 'Unnamed Category'),
                    );
                  }),
                ],
              );
            },
          ),

          // Products Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('categoryId',
                      isEqualTo: selectedCategoryId) // Filter by category
                  .snapshots(),
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
                      onEdit: widget.isAdmin
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
                      onDelete: widget.isAdmin
                          ? () {
                              FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(product.id)
                                  .delete();
                            }
                          : null,
                      isAdmin: widget.isAdmin,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
