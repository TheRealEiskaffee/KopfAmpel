class Category {
  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.isCustom = true,
  });

  final int id;
  final String name;

  /// Icon key into `kCategoryIcons` (see app/theme/category_icons.dart).
  final String? icon;
  final String? color;
  final int sortOrder;
  final bool isCustom;
}
