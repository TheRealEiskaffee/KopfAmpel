import 'severity.dart';
import 'tag.dart';

class HeadacheEntry {
  HeadacheEntry({
    required this.id,
    required this.date,
    required this.severity,
    this.note,
    this.triggers = const [],
    this.medications = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final DateTime date;
  final Severity severity;
  final String? note;
  final List<Tag> triggers;
  final List<MedicationEntry> medications;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MedicationEntry {
  const MedicationEntry({required this.tag, this.dose});
  final Tag tag;
  final String? dose;
}
