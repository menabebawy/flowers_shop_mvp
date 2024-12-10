import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowers_shop_mvp/screens/dashboard/product_card_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    categoriesFuture = fetchCategories();
  }

  Future<List<QueryDocumentSnapshot>> fetchCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    return snapshot.docs;
  }

  Future<void> _updateCart(String productId, int quantity) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Query for the user's pending order
    final orderQuery = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (orderQuery.docs.isNotEmpty) {
      // Update existing pending order
      final orderDoc = orderQuery.docs.first;
      final orderData = orderDoc.data();
      final products = List<Map<String, dynamic>>.from(orderData['products']);

      // Check if the product already exists in the order
      final productIndex =
          products.indexWhere((p) => p['productId'] == productId);

      if (productIndex >= 0) {
        if (quantity > 0) {
          // Update quantity
          products[productIndex]['quantity'] = quantity;
        } else {
          // Remove product if quantity is zero
          products.removeAt(productIndex);
        }
      } else if (quantity > 0) {
        // Add new product
        products.add({'productId': productId, 'quantity': quantity});
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderDoc.id)
          .update({'products': products});
    } else {
      // Create a new pending order if none exists
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': userId,
        'status': 'pending',
        'products': quantity > 0
            ? [
                {'productId': productId, 'quantity': quantity}
              ]
            : [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
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
    final userId = FirebaseAuth.instance.currentUser!.uid;

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
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('userId', isEqualTo: userId)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox(); // No pending order
                    }

                    final pendingOrder = snapshot.data!.docs.first;
                    final products = List<Map<String, dynamic>>.from(
                      pendingOrder['products'] ?? [],
                    );

                    final totalItems = products.fold<int>(
                      0,
                      (sum, product) => sum + (product['quantity'] as int),
                    );

                    if (totalItems == 0) {
                      return const SizedBox(); // Do not display badge if cart is empty
                    }

                    return Positioned(
                      right: 1,
                      // Push badge further away from the right edge of the icon
                      top: 5,
                      // Push badge slightly lower to avoid overlap
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        // Adjust padding for sizing
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(12), // Perfect circle
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18, // Badge width
                          minHeight: 18, // Badge height
                        ),
                        child: Text(
                          '$totalItems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10, // Smaller font size for compact badge
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
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
          // Category filter dropdown
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
          // Products section
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
                    return ProductCardDashboard(
                      product: product.data() as Map<String, dynamic>,
                      isAdmin: widget.isAdmin,
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
