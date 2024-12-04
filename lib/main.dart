import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flowers_shop_mvp/screens/splash_screen.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Ensure authentication persistence
  if (isWeb()) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    print('Auth persistence set for web');
  } else {
    print('Persistence is managed automatically for mobile platforms');
  }
  runApp(const FlowersShopApp());
}

bool isWeb() {
  try {
    return identical(0, 0.0);
  } catch (_) {
    return false;
  }
}

class FlowersShopApp extends StatelessWidget {
  const FlowersShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
