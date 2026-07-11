class CategoryModel {
  final int id;
  final String category;
  final String emoji;
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.category,
    required this.emoji,
    this.isDefault = false,
  });

  /// Display label combining emoji and name.
  String get label => '$emoji $category';

  CategoryModel copyWith({
    int? id,
    String? category,
    String? emoji,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

