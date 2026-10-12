class Recipe {
  final int id;
  final String title;
  final String category;
  final String difficulty;
  final int cookTime;

  const Recipe({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.cookTime,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'],
    title: json['title'],
    category: json['category'],
    difficulty: json['difficulty'],
    cookTime: json['cookTime'],
  );
}
