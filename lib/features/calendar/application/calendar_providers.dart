import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/converters.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/domain/entry.dart';
import '../../../core/domain/severity.dart';

/// Returns first/last day of the month enclosing [anchor].
({DateTime first, DateTime last}) monthBounds(DateTime anchor) {
  final first = DateTime(anchor.year, anchor.month, 1);
  final last = DateTime(anchor.year, anchor.month + 1, 0);
  return (first: first, last: last);
}

/// Stream of date → severity for the month enclosing the keyed date.
/// Allows the calendar to mark days with a coloured dot reactively.
final monthSeverityProvider =
    StreamProvider.family<Map<DateTime, Severity>, DateTime>((ref, anchor) {
  final dao = ref.watch(entriesDaoProvider);
  final bounds = monthBounds(anchor);
  return dao.watchBetween(bounds.first, bounds.last).map((rows) {
    return {
      for (final row in rows) dayKey(row.date): Severity.fromString(row.severity),
    };
  });
});

final entryByDayProvider =
    FutureProvider.family<HeadacheEntry?, DateTime>((ref, date) async {
  return ref.watch(entriesRepositoryProvider).findByDate(date);
});
