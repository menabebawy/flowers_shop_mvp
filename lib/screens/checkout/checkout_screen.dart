import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> products; // Products in the cart
  const CheckoutScreen({super.key, required this.products});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;
  bool _isFetched = false; // Track if data is fetched

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool get _isFormValid {
    return _isFetched &&
        _fullNameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _addressController.text.isNotEmpty;
  }

  double get _totalPrice {
    return widget.products.fold(0.0, (double sum, product) {
      return sum + (product['price'] * product['quantity']);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          _fullNameController.text = data['fullName'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _addressController.text = data['address'] ?? '';
        }
      }
    }

    setState(() {
      _isFetched = true; // Mark as fetched once data is loaded
    });
  }

  Future<void> _placeOrder() async {
    setState(() {
      _isProcessing = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to place an order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Save order to Firestore
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'status': 'placed',
        'createdAt': Timestamp.now(),
        'products': widget.products,
        'clientInfo': {
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneController.text,
          'address': _addressController.text,
        },
        'totalPrice': _totalPrice,
      });

      // Navigate to success screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Order Summary Section
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.products.length,
                  itemBuilder: (context, index) {
                    final product = widget.products[index];
                    return ListTile(
                      title: Text(product['name']),
                      subtitle: Text('Quantity: ${product['quantity']}'),
                      trailing:
                          Text('€${product['price'] * product['quantity']}'),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Client Data Section
                const Text(
                  'Delivery Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                // Total Price Section
                Text(
                  'Total: €${_totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Place Order Button
          Container(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid ? Colors.orange : Colors.grey,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isFormValid && !_isProcessing ? _placeOrder : null,
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Place Order',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
