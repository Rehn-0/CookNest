import 'package:flutter/material.dart';

import 'recipe_feed_screen.dart';

void main() => runApp(const CookNestApp());

class CookNestApp extends StatelessWidget {
  const CookNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CookNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const RecipeFeedScreen(),
    );
  }
}
