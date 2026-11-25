import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'cloudinary_service.dart';

class IngredientRow {
  final TextEditingController name = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  String unit = 'g';

  void dispose() {
    name.dispose();
    quantity.dispose();
  }
}

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _instructions = TextEditingController();
  final _cookTime = TextEditingController();

  static const categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Snack',
    'Drinks',
  ];
  static const difficulties = ['Easy', 'Medium', 'Hard'];
  static const units = ['g', 'kg', 'ml', 'l', 'tsp', 'tbsp', 'cup', 'piece'];

  String? _category;
  File? _image;
  String? _imageUrl;
  bool _uploading = false;
  String _difficulty = 'Easy';
  final List<IngredientRow> _ingredients = [IngredientRow()];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _instructions.dispose();
    _cookTime.dispose();
    for (final row in _ingredients) {
      row.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() => _ingredients.add(IngredientRow()));
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].dispose();
      _ingredients.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _imageUrl = null;
      });
    }
  }

  Future<void> _submit() async {
    debugPrint('SAVE PRESSED');
    if (!_formKey.currentState!.validate()) {
      debugPrint('VALIDATION FAILED');
      return;
    }
    setState(() => _uploading = true);

    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await CloudinaryService.uploadImage(_image!);
      }

      final recipe = {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'instructions': _instructions.text.trim(),
        'cook_time_minutes': int.parse(_cookTime.text.trim()),
        'category': _category,
        'difficulty': _difficulty,
        'image_url': imageUrl,
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        'created_at': FieldValue.serverTimestamp(),
        'ingredients': _ingredients
            .map(
              (r) => {
                'name': r.name.text.trim(),
                'quantity': double.parse(r.quantity.text.trim()),
                'unit': r.unit,
              },
            )
            .toList(),
      };

      await FirebaseFirestore.instance.collection('recipes').add(recipe);

      if (!mounted) return;
      setState(() => _imageUrl = imageUrl);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Recipe saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Recipe')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Recipe title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Short description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Choose a category' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    items: difficulties
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _difficulty = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cookTime,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cook time (min)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => int.tryParse(v?.trim() ?? '') == null
                        ? 'Enter minutes'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Ingredients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < _ingredients.length; i++)
              Padding(
                key: ObjectKey(_ingredients[i]),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _ingredients[i].name,
                        decoration: const InputDecoration(
                          labelText: 'Ingredient',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _ingredients[i].quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            double.tryParse(v?.trim() ?? '') == null
                            ? 'Number'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _ingredients[i].unit,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: units
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _ingredients[i].unit = v!),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _ingredients.length > 1
                          ? () => _removeIngredient(i)
                          : null,
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add),
                label: const Text('Add ingredient'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructions,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter instructions' : null,
            ),
            const SizedBox(height: 20),
            const Text(
              'Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 180, fit: BoxFit.cover),
              ),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_image == null ? 'Choose photo' : 'Change photo'),
            ),
            if (_imageUrl != null) ...[
              const SizedBox(height: 12),
              const Text('Uploaded to cloud storage:'),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _imageUrl!,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _uploading ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_uploading ? 'Saving...' : 'Save recipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
