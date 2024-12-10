import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductCardDashboard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCardDashboard({
    super.key,
    required this.product,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
  });

  Future<void> _addToCart(BuildContext context) async {
    try {
      // Get the current user's UID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to add to cart')),
        );
        return;
      }

      // Reference to Firestore
      final ordersCollection = FirebaseFirestore.instance.collection('orders');

      // Check if there's an active order for the current user
      final userOrder = await ordersCollection
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (userOrder.docs.isEmpty) {
        // Create a new order if none exists for the user
        await ordersCollection.add({
          'userId': user.uid,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'products': [
            {
              'productId': product['id'],
              'quantity': 1,
            }
          ]
        });
      } else {
        // Update the existing order
        final orderDoc = userOrder.docs.first;
        final products =
            List<Map<String, dynamic>>.from(orderDoc['products'] ?? []);

        // Check if the product already exists in the products array
        final productIndex =
            products.indexWhere((p) => p['productId'] == product['id']);
        if (productIndex != -1) {
          // Increment the quantity if the product exists
          products[productIndex]['quantity'] += 1;
        } else {
          // Add the product if it doesn't exist
          products.add({
            'productId': product['id'],
            'quantity': 1,
          });
        }

        // Update the order document with the modified products array
        await ordersCollection.doc(orderDoc.id).update({
          'products': products,
        });
      }

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product['imageUrl'] != null
                  ? Image.network(
                      product['imageUrl'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Icon(
                      Icons.image,
                      size: 80,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 16),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unnamed Product',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['price'] != null
                        ? 'Price: \$${product['price']}'
                        : 'No price available',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            isAdmin
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: onDelete,
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: () => _addToCart(context),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
