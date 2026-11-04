import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CookNestApp());
}

class CookNestApp extends StatelessWidget {
  const CookNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CookNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}
