import 'package:badges/badges.dart' as badges;
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
  int _cartCount = 0;
  String? selectedCategoryId;
  late Future<List<QueryDocumentSnapshot>> categoriesFuture;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _fetchCartCount();
    _listenToCartUpdates();
    categoriesFuture = fetchCategories();

    // Initialize _screens
    _screens = [
      _buildHomeScreen(), // Home screen
      FutureBuilder<Widget>(
        future: _getProfileScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile.'));
          }
          return snapshot.data ?? const SizedBox.shrink();
        },
      ),
      widget.isAdmin
          ? const OrdersScreen()
          : CartScreen(
              onCartUpdated: _fetchCartCount,
              onNavigateHome: () {
                _selectedIndex = 0;
              },
            ),
    ];

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

  Future<void> _fetchCartCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final orderData = querySnapshot.docs.first.data();
        final products = List<Map<String, dynamic>>.from(orderData['products']);
        setState(() {
          _cartCount = products.fold<int>(
              0, (total, item) => total + (item['quantity'] as int));
        });
      } else {
        setState(() {
          _cartCount = 0;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<Widget> _getProfileScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final additionalData = userDoc.data() ?? {};
    final localUser = LocalUser.fromFirebase(user, additionalData);

    return ProfileScreen(
      user: localUser,
      onLogout: _resetToFirstTab,
    );
  }

  Widget _buildHomeScreen() {
    return Column(
      children: [
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
                return const Text(
                  'No categories available.',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                );
              }
              final categories = snapshot.data!;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(color: Colors.black),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategoryId,
                    hint: const Text(
                      'All Categories',
                      style: TextStyle(color: Colors.white),
                    ),
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    dropdownColor: Colors.black,
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All Categories',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ...categories.map((category) {
                        final data = category.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            data['name'] ?? 'Unnamed Category',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: selectedCategoryId != null
                ? FirebaseFirestore.instance
                    .collection('products')
                    .where('categoryId', isEqualTo: selectedCategoryId)
                    .snapshots()
                : FirebaseFirestore.instance.collection('products').snapshots(),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product =
                      products[index].data() as Map<String, dynamic>;
                  return ProductCardHome(
                    product: product,
                    onTap: () => addToCart(product),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _resetToFirstTab() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _listenToCartUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          final orderData = querySnapshot.docs.first.data();
          final products =
              List<Map<String, dynamic>>.from(orderData['products']);
          setState(() {
            _cartCount = products.fold<int>(
                0, (total, item) => total + (item['quantity'] as int));
          });
        } else {
          setState(() {
            _cartCount = 0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade400,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: widget.isAdmin
                ? const Icon(Icons.list)
                : badges.Badge(
                    showBadge: _cartCount > 0,
                    badgeContent: Text(
                      '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.orange,
                    ),
                    child: const Icon(Icons.shopping_cart),
                  ),
            label: widget.isAdmin ? 'Orders' : 'Cart',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void addToCart(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final ordersCollection = FirebaseFirestore.instance.collection('orders');
      final querySnapshot = await ordersCollection
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final orderDoc = querySnapshot.docs.first;
        final orderData = orderDoc.data();
        final products = List<Map<String, dynamic>>.from(orderData['products']);
        final existingProductIndex =
            products.indexWhere((p) => p['productId'] == product['id']);

        if (existingProductIndex != -1) {
          products[existingProductIndex]['quantity'] += 1;
        } else {
          products.add({'productId': product['id'], 'quantity': 1});
        }

        await ordersCollection.doc(orderDoc.id).update({'products': products});
      } else {
        await ordersCollection.add({
          'userId': user.uid,
          'status': 'pending',
          'createdAt': DateTime.now(),
          'products': [
            {'productId': product['id'], 'quantity': 1}
          ],
        });
      }
    }

    await _fetchCartCount();

    // Show a visually enhanced SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "'${product['name']}' has been added to your cart!",
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.orangeAccent,
          onPressed: () {
            setState(() {
              _selectedIndex = 2; // Navigate to Cart Screen
            });
          },
        ),
      ),
    );
  }
}
