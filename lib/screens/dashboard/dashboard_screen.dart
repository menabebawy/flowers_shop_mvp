import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowers_shop_mvp/screens/authentication/login_screen.dart';
import 'package:flowers_shop_mvp/screens/dashboard/cart_screen.dart';
import 'package:flowers_shop_mvp/screens/dashboard/profile_screen.dart';
import 'package:flowers_shop_mvp/views/product_card_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/local_user.dart';
import '../checkout/order_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isAdmin;

  const DashboardScreen({super.key, required this.isAdmin});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? selectedCategoryId;
  late Future<List<QueryDocumentSnapshot>> categoriesFuture;

  @override
  void initState() {
    super.initState();
    categoriesFuture = fetchCategories();
    // Ensure status bar icons are white for visibility
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<List<QueryDocumentSnapshot>> fetchCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    return snapshot.docs;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<Widget> _getSelectedScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    final LocalUser? localUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final additionalData = userDoc.data() ?? {};
      localUser = LocalUser.fromFirebase(user, additionalData);
    } else {
      localUser = null;
    }

    switch (_selectedIndex) {
      case 1:
        return localUser == null
            ? const LoginScreen()
            : ProfileScreen(
                user: localUser,
                onLogout: _resetToFirstTab, // Pass the reset callback,
              );
      case 2:
        return widget.isAdmin ? const OrdersScreen() : const CartScreen();
      case 0:
      default:
        return Column(
          children: [
            // Top Bar with Category Dropdown
            AppBar(
              backgroundColor: Colors.black,
              centerTitle: true,
              title: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(color: Colors.white);
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No categories available.',
                        style: TextStyle(fontSize: 16, color: Colors.white));
                  }
                  final categories = snapshot.data!;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(color: Colors.black),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategoryId,
                        hint: const Text('All Categories',
                            style: TextStyle(color: Colors.white)),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white),
                        dropdownColor: Colors.black,
                        onChanged: (value) {
                          setState(() {
                            selectedCategoryId = value;
                          });
                        },
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Categories',
                                style: TextStyle(color: Colors.white)),
                          ),
                          ...categories.map((category) {
                            final data =
                                category.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: category.id,
                              child: Text(data['name'] ?? 'Unnamed Category',
                                  style: const TextStyle(color: Colors.white)),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Product Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedCategoryId != null
                    ? FirebaseFirestore.instance
                        .collection('products')
                        .where('categoryId', isEqualTo: selectedCategoryId)
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('products')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No products available.'));
                  }
                  final products = snapshot.data!.docs;
                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product =
                          products[index].data() as Map<String, dynamic>;
                      return ProductCardHome(product: product);
                    },
                  );
                },
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0; // Navigate to home when back button is pressed
          });
          return false; // Prevent the app from closing
        }
        return true; // Allow app to close if on the home screen
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FutureBuilder<Widget>(
          future: _getSelectedScreen(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else if (snapshot.hasData && snapshot.data != null) {
              return snapshot.data!;
            } else {
              return const Center(child: Text('No data available'));
            }
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade400,
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Profile'),
            BottomNavigationBarItem(
              icon: Icon(widget.isAdmin ? Icons.list : Icons.shopping_cart),
              label: widget.isAdmin ? 'Orders' : 'Cart',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  void _resetToFirstTab() {
    setState(() {
      _selectedIndex = 0; // Reset to the first tab
    });
  }
}
