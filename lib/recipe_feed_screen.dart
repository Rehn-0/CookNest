import 'dart:convert';

import 'phone_verify_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'add_recipe_screen.dart';
import 'recipe.dart';
import 'recipe_detail_screen.dart';

class RecipeFeedScreen extends StatefulWidget {
  const RecipeFeedScreen({super.key});

  @override
  State<RecipeFeedScreen> createState() => _RecipeFeedScreenState();
}

class _RecipeFeedScreenState extends State<RecipeFeedScreen> {
  // 10.0.2.2 is how the Android emulator reaches your Mac's localhost
  static const baseUrl = 'http://10.0.2.2:3000';
  static const pageSize = 5;

  final _scroll = ScrollController();
  final List<Recipe> _recipes = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_loading || _page > _totalPages) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/recipes?page=$_page&limit=$pageSize'),
      );
      if (res.statusCode != 200) throw Exception('Server ${res.statusCode}');

      final body = jsonDecode(res.body);
      final items = (body['data'] as List)
          .map((j) => Recipe.fromJson(j as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _recipes.addAll(items);
        _totalPages = body['totalPages'];
        _page++;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load recipes';
        _loading = false;
      });
      return;
    }

    // If the loaded items don't fill the screen, there is nothing to scroll,
    // so keep loading until the screen is full or the pages run out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients && _scroll.position.maxScrollExtent <= 0) {
        _loadPage();
      }
    });
  }

  Widget _footer() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextButton(
            onPressed: _loadPage,
            child: Text('$_error. Tap to retry'),
          ),
        ),
      );
    }
    if (_page > _totalPages) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text("You've reached the end")),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CookNest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_android),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PhoneVerifyScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scroll,
        itemCount: _recipes.length + 1,
        itemBuilder: (context, index) {
          if (index == _recipes.length) return _footer();
          final r = _recipes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(recipe: r),
                ),
              ),
              title: Text(r.title),
              subtitle: Text(
                '${r.category} • ${r.difficulty} • ${r.cookTime} min',
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add recipe'),
      ),
    );
  }
}
