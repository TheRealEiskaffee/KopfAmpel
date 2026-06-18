class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.categoryId,
    this.isCustom = true,
    this.color,
  });

  final int id;
  final String name;
  final int categoryId;
  final bool isCustom;
  final String? color;
}
