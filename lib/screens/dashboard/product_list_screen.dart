import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowers_shop_mvp/screens/dashboard/product_card_dashboard.dart';
import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  final bool isAdmin; // Accept isAdmin as a parameter

  const ProductListScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              return ProductCardDashboard(
                product: product,
                isAdmin: isAdmin, // Pass the isAdmin flag
              );
            },
          );
        },
      ),
    );
  }
}
