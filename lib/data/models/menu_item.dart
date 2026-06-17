class MenuItem {
  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.prepMinutes = 10,
    this.calories,
    this.imagePath,
    List<String>? tags,
  }) : tags = tags ?? [];

  final String id;
  final String name;
  final String description;
  double price;
  final String category;
  bool isAvailable;
  int prepMinutes;
  final int? calories;
  final String? imagePath;
  final List<String> tags;

  // Computed for backwards compat with existing card/badge code
  bool get isFeatured => tags.contains('Featured');

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    bool? isAvailable,
    String? imagePath,
    List<String>? tags,
  }) =>
      MenuItem(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        category: category,
        isAvailable: isAvailable ?? this.isAvailable,
        prepMinutes: prepMinutes,
        calories: calories,
        imagePath: imagePath ?? this.imagePath,
        tags: tags ?? List.of(this.tags),
      );
}
