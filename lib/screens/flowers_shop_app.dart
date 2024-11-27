import 'package:flutter/material.dart';

import 'product_list_screen.dart';

class FlowersShopApp extends StatelessWidget {
  const FlowersShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flower Shop'),
        ),
        body: const ProductListScreen(),
      ),
    );
  }
}
