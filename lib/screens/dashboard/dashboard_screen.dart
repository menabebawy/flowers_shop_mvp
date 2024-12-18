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
  Map<String, dynamic>? selectedProduct;
  String? selectedCategoryId;
  late Future<List<QueryDocumentSnapshot>> categoriesFuture;
  List<Map<String, dynamic>> localCart = [];

  @override
  void initState() {
    super.initState();
    _fetchCartCount();
    _listenToCartUpdates();
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

  Future<Widget> _getSelectedScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    LocalUser? localUser;

    // Fetch user details if logged in
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final additionalData = userDoc.data() ?? {};
      localUser = LocalUser.fromFirebase(user, additionalData);
    }

    // Determine the selected tab and return the appropriate screen
    switch (_selectedIndex) {
      case 1: // Profile Screen
        return user == null
            ? const LoginScreen() // Redirect to login if not logged in
            : ProfileScreen(
                user: localUser!,
                onLogout: _resetToFirstTab,
              );

      case 2: // Cart or Orders Screen
        return widget.isAdmin
            ? const OrdersScreen() // Admin sees orders
            : CartScreen(
                onNavigateHome: () {
                  setState(() {
                    _selectedIndex = 0; // Navigate to Home tab
                  });
                },
                onCartUpdated: _fetchCartCount, // Update cart badge dynamically
              );

      case 0: // Home Screen
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
                            child: Text(
                              'All Categories',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ...categories.map((category) {
                            final data =
                                category.data() as Map<String, dynamic>;
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
              icon: widget.isAdmin
                  ? const Icon(Icons.list)
                  : badges.Badge(
                      showBadge: _cartCount > 0,
                      // Show badge only if the cart count > 0
                      badgeContent: Text(
                        '$_cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: Colors.orange, // Set badge color to orange
                      ),
                      child:
                          const Icon(Icons.shopping_cart), // Shopping cart icon
                    ),
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

  void openCartWithProduct(Map<String, dynamic> product) {
    setState(() {
      selectedProduct = product; // Set the selected product
      _selectedIndex = 2; // Navigate to the cart screen
    });
  }

  void addToCart(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Reference to the orders collection
      final ordersCollection = FirebaseFirestore.instance.collection('orders');

      // Check for an existing pending order for the user
      final querySnapshot = await ordersCollection
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // A pending order exists, update it
        final orderDoc = querySnapshot.docs.first;
        final orderData = orderDoc.data();
        final products = List<Map<String, dynamic>>.from(orderData['products']);

        // Check if the product already exists in the order
        final existingProductIndex = products.indexWhere(
          (p) => p['productId'] == product['id'],
        );

        if (existingProductIndex != -1) {
          // Update the quantity of the existing product
          products[existingProductIndex]['quantity'] += 1;
        } else {
          // Add the new product to the order
          products.add({'productId': product['id'], 'quantity': 1});
        }

        // Update the order in Firestore
        await ordersCollection.doc(orderDoc.id).update({'products': products});
      } else {
        // No pending order exists, create a new one
        await ordersCollection.add({
          'userId': user.uid,
          'status': 'pending',
          'createdAt': DateTime.now(),
          'products': [
            {'productId': product['productId'], 'quantity': 1},
          ],
        });
      }
    } else {
      // Handle unauthenticated users with a local cart
      localCart.add(product);
    }

    // Refresh cart count
    await _fetchCartCount();

    // Show feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product['name']} added to cart!',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
    );
  }
}
