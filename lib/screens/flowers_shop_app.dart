import 'package:flutter/material.dart';

import 'authentication/login_screen.dart';

class FlowersShopApp extends StatelessWidget {
  const FlowersShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
