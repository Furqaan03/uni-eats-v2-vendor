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
    this.discountPercent,
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
  // 0–100 percent discount on this item, set by vendor
  double? discountPercent;
  final List<String> tags;

  bool get isFeatured => tags.contains('Featured');
  bool get hasDiscount =>
      discountPercent != null && discountPercent! > 0;
  double get discountedPrice =>
      hasDiscount ? price * (1 - discountPercent! / 100) : price;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'isAvailable': isAvailable,
        'prepMinutes': prepMinutes,
        'calories': calories,
        'imagePath': imagePath,
        'discountPercent': discountPercent,
        'tags': tags,
      };

  factory MenuItem.fromMap(Map<String, dynamic> map) => MenuItem(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        category: map['category'] as String? ?? '',
        isAvailable: map['isAvailable'] as bool? ?? true,
        prepMinutes: (map['prepMinutes'] as num?)?.toInt() ?? 10,
        calories: (map['calories'] as num?)?.toInt(),
        imagePath: map['imagePath'] as String?,
        discountPercent: (map['discountPercent'] as num?)?.toDouble(),
        tags: (map['tags'] as List<dynamic>?)?.cast<String>(),
      );

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    bool? isAvailable,
    String? imagePath,
    List<String>? tags,
    double? discountPercent,
    bool clearDiscount = false,
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
        discountPercent:
            clearDiscount ? null : (discountPercent ?? this.discountPercent),
        tags: tags ?? List.of(this.tags),
      );
}
