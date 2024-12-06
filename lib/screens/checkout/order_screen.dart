import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Fetch orders from Firestore
  Stream<List<QueryDocumentSnapshot>> fetchOrders() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs);
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
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text('Order ID: ${orders[index].id}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${order['status']}'),
                Text(
                    'Total Price: \$${(order['totalPrice'] ?? 0).toStringAsFixed(2)}'),
                Text('Date: ${order['createdAt']?.toDate()?.toLocal()}'),
              ],
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
}

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details ($orderId)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: $orderId',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text('Status: ${orderData['status']}'),
            Text(
                'Total Price: \$${(orderData['totalPrice'] ?? 0).toStringAsFixed(2)}'),
            Text('Created At: ${orderData['createdAt']?.toDate()?.toLocal()}'),
            const SizedBox(height: 16),
            const Text('Products:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate((orderData['products'] as List).length, (index) {
              final product = orderData['products'][index];
              return ListTile(
                title: Text(product['name']),
                subtitle: Text('Quantity: ${product['quantity']}'),
                trailing: Text(
                    '\$${(product['price'] * product['quantity']).toStringAsFixed(2)}'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
