import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrderDetailScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const AdminOrderDetailScreen(
      {super.key, required this.orderId, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final deliveryInfo = orderData['deliveryInfo'] ?? {};
    final address = deliveryInfo['address'] ?? 'No address provided';
    final fullName = deliveryInfo['fullName'] ?? 'Unknown';
    final phoneNumber = deliveryInfo['phoneNumber'] ?? 'No phone number';
    final products = orderData['products'] as List<dynamic>? ?? [];
    final status = orderData['status'] ?? 'unknown';
    final completedAt = orderData['completedAt'];
    final deliveredAt = orderData['deliveredAt'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bestelldetails',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.black,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Content Scrollable Section
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lieferinformationen',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                    title: Text(fullName),
                    subtitle: Text('Adresse: $address\nTelefon: $phoneNumber'),
                  ),
                  const Divider(),
                  // Items Section
                  const Text(
                    'Artikel',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    itemCount: products.length,
                    shrinkWrap: true, // Prevents infinite height
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final productId = product['productId'] ?? 'Unbekannt';
                      final quantity = product['quantity'] ?? 1;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('products')
                            .doc(productId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ListTile(
                              title: Text('Produkt wird geladen...'),
                            );
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              !snapshot.data!.exists) {
                            return ListTile(
                              title: Text(
                                  'Produkt nicht gefunden (ID: $productId)'),
                              subtitle: Text('Menge: $quantity'),
                            );
                          }

                          final productData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final productName =
                              productData['name'] ?? 'Unbekanntes Produkt';
                          final productPrice =
                              productData['price'] ?? 0.0; // Price fallback

                          return ListTile(
                            leading: const Icon(Icons.shopping_cart),
                            title: Text(productName),
                            subtitle: Text(
                                'Menge: $quantity\nPreis: \$${(productPrice * quantity).toStringAsFixed(2)}'),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(),
                  // Total Section
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<double>(
                    future: _calculateTotal(products),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Gesamtbetrag wird berechnet...');
                      }
                      if (snapshot.hasError) {
                        return const Text(
                          'Fehler bei der Berechnung des Gesamtbetrags.',
                          style: TextStyle(color: Colors.red),
                        );
                      }

                      final total = snapshot.data ?? 0.0;
                      return Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  if (completedAt != null) const Divider(),
                  if (status == 'completed' || status == 'delivered') ...[
                    const SizedBox(height: 16),
                    _buildTimestampRow(
                      icon: Icons.check_circle,
                      label: 'Abgeschlossen am',
                      timestamp: completedAt,
                      color: Colors.green,
                    ),
                  ],
                  if (status == 'delivered') ...[
                    const SizedBox(height: 8),
                    _buildTimestampRow(
                      icon: Icons.local_shipping,
                      label: 'Geliefert am',
                      timestamp: deliveredAt,
                      color: Colors.blue,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Conditional Button at the Bottom
          if (status != 'delivered')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 16.0, left: 16.0, right: 16.0, bottom: 32),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (status == 'placed') {
                      await _markOrderAsCompleted(context);
                    } else if (status == 'completed') {
                      await _markOrderAsDelivered(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        status == 'placed' ? Colors.green : Colors.black,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Remove corner radius
                    ),
                  ),
                  child: Text(
                    status == 'placed'
                        ? 'Als Abgeschlossen markieren'
                        : 'Als geliefert markieren',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimestampRow({
    required IconData icon,
    required String label,
    required Timestamp? timestamp,
    required Color color,
  }) {
    final formattedDate = timestamp != null
        ? DateFormat('MMMM dd, yyyy, h:mm a').format(timestamp.toDate())
        : 'N/A';
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: $formattedDate',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _markOrderAsCompleted(BuildContext context) async {
    try {
      final completedAt = Timestamp.now();
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'completed',
        'completedAt': completedAt,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bestellung als abgeschlossen markiert!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Aktualisieren der Bestellung: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markOrderAsDelivered(BuildContext context) async {
    try {
      final deliveredAt = Timestamp.now();
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'delivered',
        'deliveredAt': deliveredAt,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bestellung als geliefert markiert!'),
          backgroundColor: Colors.blue,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Aktualisieren der Bestellung: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<double> _calculateTotal(List<dynamic> products) async {
    double total = 0.0;

    for (var product in products) {
      final productId = product['productId'];
      final quantity = product['quantity'] ?? 1;

      if (productId != null) {
        try {
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

          if (productDoc.exists) {
            final productData = productDoc.data() as Map<String, dynamic>;
            final productPrice = productData['price'] ?? 0.0;
            total += productPrice * quantity;
          }
        } catch (e) {
          // Handle errors gracefully
        }
      }
    }

    return total;
  }
}
