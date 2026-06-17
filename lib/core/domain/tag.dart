import 'tag_kind.dart';

class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.kind,
    this.isCustom = true,
    this.color,
  });

  final int id;
  final String name;
  final TagKind kind;
  final bool isCustom;
  final String? color;
}
