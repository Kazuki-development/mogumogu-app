
// Model class
enum FoodCategory {
  meat,     // 3 days
  dairy,    // 7 days
  vegetable, // 7 days
  frozen,   // 30 days
  pantry,   // 60 days
  other
}

class FoodItem {
  final int? id;
  final String name;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final FoodCategory category;
  final String? imagePath;
  final List<int> notificationSettings;
  final String? customIcon;
  final int? orderIndex;

  FoodItem({
    this.id,
    required this.name,
    required this.purchaseDate,
    required this.expiryDate,
    required this.category,
    this.imagePath,
    this.notificationSettings = const [1], // Default: 1 day before
    this.customIcon,
    this.orderIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'category': category.index,
      'imagePath': imagePath,
      'notificationSettings': notificationSettings.join(','),
      'customIcon': customIcon,
      'orderIndex': orderIndex,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      purchaseDate: DateTime.parse(map['purchaseDate']),
      expiryDate: DateTime.parse(map['expiryDate']),
      category: FoodCategory.values[map['category']],
      imagePath: map['imagePath'],
      notificationSettings: map['notificationSettings'] != null
          ? (map['notificationSettings'] as String)
              .split(',')
              .map((e) => int.tryParse(e) ?? 1)
              .toList()
          : [1],
      customIcon: map['customIcon'],
      orderIndex: map['orderIndex'],
    );
  }

  FoodItem copyWith({
    int? id,
    String? name,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    FoodCategory? category,
    String? imagePath,
    List<int>? notificationSettings,
    String? customIcon,
    int? orderIndex,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      customIcon: customIcon ?? this.customIcon,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
