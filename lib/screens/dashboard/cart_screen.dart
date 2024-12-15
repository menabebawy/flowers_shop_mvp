import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cart = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final orderDoc = querySnapshot.docs.first;
        final orderData = orderDoc.data();

        final products = List<Map<String, dynamic>>.from(orderData['products']);
        final detailedCart = await Future.wait(products.map((product) async {
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(product['productId'])
              .get();

          if (productDoc.exists) {
            final productData = productDoc.data();
            return {
              'orderId': orderDoc.id,
              'productId': product['productId'],
              'quantity': product['quantity'],
              'name': productData?['name'] ?? 'Unnamed Product',
              'price': productData?['price'] ?? 0.0,
              'imageUrl': productData?['imageUrl'],
            };
          } else {
            return {
              'orderId': orderDoc.id,
              'productId': product['productId'],
              'quantity': product['quantity'],
              'name': 'Unknown Product',
              'price': 0.0,
              'imageUrl': null,
            };
          }
        }));

        setState(() {
          cart = detailedCart;
          isLoading = false;
        });
      } else {
        setState(() {
          cart = [];
          isLoading = false;
        });
      }
    } else {
      setState(() {
        cart = [];
        isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(
      String orderId, String productId, int newQuantity) async {
    final orderRef =
        FirebaseFirestore.instance.collection('orders').doc(orderId);
    final orderDoc = await orderRef.get();

    if (orderDoc.exists) {
      final orderData = orderDoc.data();
      final products = List<Map<String, dynamic>>.from(orderData!['products']);

      final index = products.indexWhere((p) => p['productId'] == productId);
      if (index != -1) {
        products[index]['quantity'] = newQuantity;

        await orderRef.update({'products': products});

        setState(() {
          cart.firstWhere((p) => p['productId'] == productId)['quantity'] =
              newQuantity;
        });
      }
    }
  }

  Future<void> _removeItem(String orderId, String productId) async {
    final orderRef =
        FirebaseFirestore.instance.collection('orders').doc(orderId);
    final orderDoc = await orderRef.get();

    if (orderDoc.exists) {
      final orderData = orderDoc.data();
      final products = List<Map<String, dynamic>>.from(orderData!['products']);

      products.removeWhere((p) => p['productId'] == productId);

      await orderRef.update({'products': products});

      setState(() {
        cart.removeWhere((p) => p['productId'] == productId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Cart'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : cart.isEmpty
                    ? const Center(child: Text('Your cart is empty.'))
                    : ListView.builder(
                        itemCount: cart.length,
                        padding: const EdgeInsets.only(bottom: 100),
                        itemBuilder: (context, index) {
                          final item = cart[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                // Product Image
                                Container(
                                  height:
                                      MediaQuery.of(context).size.width * 0.3,
                                  width:
                                      MediaQuery.of(context).size.width * 0.3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: item['imageUrl'] != null
                                        ? DecorationImage(
                                            image:
                                                NetworkImage(item['imageUrl']),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: Colors.grey.shade200,
                                  ),
                                  child: item['imageUrl'] == null
                                      ? const Center(
                                          child: Icon(Icons.image,
                                              size: 40, color: Colors.grey),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),

                                // Product Details and Quantity/Delete Section
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name and Price
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '€${item['price'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Dynamic Spacer for Quantity
                                      const SizedBox(
                                        height: 30, // Dynamic adjustment
                                      ),

                                      // Quantity and Delete Row
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.orange,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              // Add padding inside the border
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                    onTap: item['quantity'] > 1
                                                        ? () {
                                                            _updateQuantity(
                                                                item['orderId'],
                                                                item[
                                                                    'productId'],
                                                                item['quantity'] -
                                                                    1);
                                                          }
                                                        : null,
                                                    child: Container(
                                                      height: 30,
                                                      width: 30,
                                                      color: Colors.transparent,
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.remove,
                                                          size: 30,
                                                          color:
                                                              item['quantity'] >
                                                                      1
                                                                  ? Colors.black
                                                                  : Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16),
                                                    child: Text(
                                                      '${item['quantity']}',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      _updateQuantity(
                                                          item['orderId'],
                                                          item['productId'],
                                                          item['quantity'] + 1);
                                                    },
                                                    child: Container(
                                                      height: 30,
                                                      width: 30,
                                                      color: Colors.transparent,
                                                      child: const Center(
                                                        child: Icon(Icons.add,
                                                            size: 30,
                                                            color:
                                                                Colors.black),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => _removeItem(
                                                item['orderId'],
                                                item['productId']),
                                            child: const Row(
                                              children: [
                                                Text(
                                                  '| Delete',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(
                                                  Icons.delete_outline,
                                                  size: 20,
                                                  color: Colors.black87,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).viewPadding.bottom + 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                // Checkout logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 60),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text(
                'Checkout',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
