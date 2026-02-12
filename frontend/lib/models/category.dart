class MainCategory {
  final int id;
  final String name;
  final String nameEn;
  final String iconName;

  MainCategory({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.iconName,
  });

  factory MainCategory.fromJson(Map<String, dynamic> json) {
    return MainCategory(
      id: json['id'],
      name: json['name'],
      nameEn: json['name_en'],
      iconName: json['icon_name'],
    );
  }
}

class Category {
  final int id;
  final int mainCategoryId;
  final String name;
  final String nameEn;

  Category({
    required this.id,
    required this.mainCategoryId,
    required this.name,
    required this.nameEn,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      mainCategoryId: json['main_category_id'],
      name: json['name'],
      nameEn: json['name_en'],
    );
  }
}
