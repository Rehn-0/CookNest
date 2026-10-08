import 'package:flutter/material.dart';

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final recipe = {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'instructions': _instructions.text.trim(),
      'cook_time_minutes': int.parse(_cookTime.text.trim()),
      'category': _category,
      'difficulty': _difficulty,
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

    debugPrint(recipe.toString());
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Recipe saved (demo)')));
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
            FilledButton(
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Save recipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
