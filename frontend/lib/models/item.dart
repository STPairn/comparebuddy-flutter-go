class Item {
  final int id;
  final int categoryId;
  final String brand;
  final String name;
  final String duration;
  final double price;
  final String field;

  Item({
    required this.id,
    required this.categoryId,
    required this.brand,
    required this.name,
    required this.duration,
    required this.price,
    required this.field,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      categoryId: json['category_id'],
      brand: json['brand'],
      name: json['name'],
      duration: json['duration'],
      price: (json['price'] as num).toDouble(),
      field: json['field'] ?? '',
    );
  }
}
