import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
    required this.orderData,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late List<Map<String, dynamic>> products;
  late String status;
  late double total;

  @override
  void initState() {
    super.initState();
    products = List<Map<String, dynamic>>.from(widget.orderData['products']);
    status = widget.orderData['status'] ?? 'Unknown';
    fetchProductDetails();
  }

  // Fetch product details (name and price) from Firestore
  Future<void> fetchProductDetails() async {
    for (var product in products) {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(product['productId'])
          .get();

      if (productDoc.exists) {
        product['name'] = productDoc.data()?['name'] ?? 'Unknown Product';
        product['price'] = productDoc.data()?['price'] ?? 0.0;
      } else {
        product['name'] = 'Unknown Product';
        product['price'] = 0.0;
      }
    }
    // Recalculate total after fetching product details
    setState(() {
      total = calculateTotal();
    });
  }

  // Calculate total price
  double calculateTotal() {
    return products.fold(0.0, (sum, product) {
      return sum + ((product['price'] ?? 0) * (product['quantity'] ?? 0));
    });
  }

  // Update quantity in Firestore
  Future<void> updateOrderInFirestore() async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({'products': products});
  }

  // Handle quantity update
  void updateQuantity(int index, int delta) {
    setState(() {
      // Update the quantity
      products[index]['quantity'] = (products[index]['quantity'] ?? 0) + delta;

      if (products[index]['quantity'] <= 0) {
        // Remove the product if quantity is 0
        products.removeAt(index);
      }

      // Recalculate the total
      total = calculateTotal();
    });

    // Update Firestore with the updated product list
    updateOrderInFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details (${widget.orderId})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: ${widget.orderId}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Status: $status'),
            const SizedBox(height: 8),
            Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Products:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(product['name'] ?? 'Unknown Product'),
                      subtitle: Text('Price: \$${product['price']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              updateQuantity(index, -1);
                            },
                          ),
                          Text('${product['quantity']}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              updateQuantity(index, 1);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
