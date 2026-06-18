import 'severity.dart';
import 'tag.dart';

class HeadacheEntry {
  HeadacheEntry({
    required this.id,
    required this.date,
    required this.severity,
    this.note,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final DateTime date;
  final Severity severity;
  final String? note;
  final List<Tag> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
}
