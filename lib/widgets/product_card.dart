import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final name = product['name'] ?? 'No Name';
    final price = product['price'] ?? 0;
    final imageUrl = product['image'];

    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        title: Text(name),
        subtitle: Text('Price: \$${price.toString()}'),
        leading: imageUrl != null
            ? Image.network(
                imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 50);
                },
              )
            : const Icon(Icons.image, size: 50),
      ),
    );
  }
}
