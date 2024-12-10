import 'package:flutter/material.dart';

class ProductCardCart extends StatefulWidget {
  final Map<String, dynamic> product;
  final int initialQuantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const ProductCardCart({
    super.key,
    required this.product,
    required this.initialQuantity,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<ProductCardCart> createState() => _ProductCardCartState();
}

class _ProductCardCartState extends State<ProductCardCart> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.initialQuantity;
  }

  void _incrementQuantity() {
    setState(() {
      quantity++;
    });
    widget.onQuantityChanged(quantity);
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
      widget.onQuantityChanged(quantity);
    } else {
      widget.onRemove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        leading: widget.product['imageUrl'] != null
            ? Image.network(
          widget.product['imageUrl'],
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            );
          },
        )
            : const Icon(
          Icons.image,
          size: 50,
          color: Colors.grey,
        ),
        title: Text(
          widget.product['name'] ?? 'Unnamed Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(widget.product['price'] != null
            ? 'Price: \$${widget.product['price']}'
            : 'No price available'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: _decrementQuantity,
            ),
            Text('$quantity', style: const TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _incrementQuantity,
            ),
          ],
        ),
      ),
    );
  }
}
