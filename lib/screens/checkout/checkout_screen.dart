import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'cart.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Cart cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  Future<void> _submitOrder() async {
    final order = {
      "products": widget.cart.items,
      "userDetails": {
        "name": _nameController.text,
        "phone": _phoneController.text,
        "address": _addressController.text,
      },
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('orders').add(order);

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const OrderConfirmationScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitOrder,
              child: const Text('Submit Order'),
            ),
          ],
        ),
      ),
    );
  }
}
