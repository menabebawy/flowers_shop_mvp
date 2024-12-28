import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowers_shop_mvp/screens/admin/admin_order_detail_screen.dart';
import 'package:flutter/material.dart';

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

  Stream<List<QueryDocumentSnapshot>> fetchOrders() {
    return FirebaseFirestore.instance
        .collection('orders')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No orders found.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          final orders = snapshot.data!;
          final processingOrders =
              orders.where((order) => order['status'] == 'placed').toList();
          final completedOrders =
              orders.where((order) => order['status'] == 'completed').toList();
          final deliveredOrders =
              orders.where((order) => order['status'] == 'delivered').toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  tabs: [
                    Tab(text: 'Processing'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Delivered'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      buildOrderList(processingOrders, 'No orders processing.'),
                      buildOrderList(completedOrders, 'No completed orders.'),
                      buildOrderList(deliveredOrders, "No delivered orders.")
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
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index].data() as Map<String, dynamic>;
        final products = order['products'] as List;
        final deliveryInfo = order['deliveryInfo'];
        final address = deliveryInfo?['address'] ?? 'No address provided';
        final status = order['status'];
        final statusColor = _getStatusColor(status);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              'Address: $address',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder(
                  future: fetchProductSummaryAndTotal(products),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading products...');
                    }
                    if (snapshot.hasError) {
                      return const Text('Error loading products.');
                    }

                    final data = snapshot.data as Map<String, dynamic>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Products: ${data['summary']}'),
                        Text(
                          'Total: \$${data['total']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Status: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminOrderDetailScreen(
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

    final futures = products.map((product) async {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(product['productId'])
          .get();

      final productName = productDoc.data()?['name'] ?? 'Unknown Product';
      final productPrice = productDoc.data()?['price'] ?? 0.0;
      final quantity = product['quantity'] ?? 0;

      totalPrice += productPrice * quantity;
      productSummaries.add('$quantity x $productName');
    });

    await Future.wait(futures);

    return {
      'summary': productSummaries.join(', '),
      'total': totalPrice.toStringAsFixed(2),
    };
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'placed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'delivered':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}
