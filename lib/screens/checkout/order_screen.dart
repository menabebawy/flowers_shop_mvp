import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Stream<List<QueryDocumentSnapshot>> ordersStream;

  @override
  void initState() {
    super.initState();
    ordersStream = fetchOrders();
  }

  // Fetch orders from Firestore
  Stream<List<QueryDocumentSnapshot>> fetchOrders() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<String> fetchProductNames(List products) async {
    List<String> productNames = [];

    for (var product in products) {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(product['productId'])
          .get();
      final productName = productDoc.data()?['name'] ?? 'Unknown Product';
      productNames.add('${product['quantity']}x $productName');
    }

    return productNames.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no orders.'));
          }

          final orders = snapshot.data!;
          final pendingOrders =
              orders.where((order) => order['status'] == 'pending').toList();
          final currentOrders =
              orders.where((order) => order['status'] == 'processing').toList();
          final pastOrders =
              orders.where((order) => order['status'] == 'completed').toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Pending'),
                    Tab(text: 'Current'),
                    Tab(text: 'Past'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      buildOrderList(pendingOrders, 'No pending orders.'),
                      buildOrderList(currentOrders, 'No current orders.'),
                      buildOrderList(pastOrders, 'No past orders.'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildOrderList(
      List<QueryDocumentSnapshot> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index].data() as Map<String, dynamic>;
        final products = order['products'] as List;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: FutureBuilder(
              future: fetchProductSummaryAndTotal(products),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Calculating Total...');
                }
                if (snapshot.hasError) {
                  return const Text('Error loading total.');
                }

                final data = snapshot.data as Map<String, dynamic>;
                return Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Total: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: '\$${data['total']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            subtitle: FutureBuilder(
              future: fetchProductSummaryAndTotal(products),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading products...');
                }
                if (snapshot.hasError) {
                  return const Text('Error loading products.');
                }

                final data = snapshot.data as Map<String, dynamic>;
                return Text('Products: ${data['summary']}');
              },
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(
                      orderId: orders[index].id,
                      orderData: order,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> fetchProductSummaryAndTotal(
      List products) async {
    List<String> productSummaries = [];
    double totalPrice = 0.0;

    for (var product in products) {
      // Fetch the product details from the 'products' collection
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(product['productId'])
          .get();

      final productName = productDoc.data()?['name'] ?? 'Unknown Product';
      final productPrice =
          productDoc.data()?['price'] ?? 0.0; // Default to 0 if missing
      final quantity = product['quantity'] ?? 0;

      // Add to the total price
      totalPrice += productPrice * quantity;

      // Add product summary (e.g., "2 Roses")
      productSummaries.add('$quantity $productName');
    }

    // Return both the total price and product summary
    return {
      'summary': productSummaries.join(', '), // e.g., "2 Roses, 1 Lily"
      'total': totalPrice.toStringAsFixed(2), // e.g., "35.00"
    };
  }
}
