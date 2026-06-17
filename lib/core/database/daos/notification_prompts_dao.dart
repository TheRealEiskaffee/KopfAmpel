import 'package:drift/drift.dart';

import '../app_database.dart';
import '../converters.dart';
import '../tables/notification_prompts.dart';

part 'notification_prompts_dao.g.dart';

@DriftAccessor(tables: [NotificationPrompts])
class NotificationPromptsDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationPromptsDaoMixin {
  NotificationPromptsDao(super.db);

  Future<int> insertPrompt({
    required DateTime dayKey,
    required DateTime scheduledFor,
    required int platformId,
  }) {
    return into(notificationPrompts).insert(
      NotificationPromptsCompanion.insert(
        dayKey: dayKey,
        scheduledFor: scheduledFor,
        platformId: platformId,
      ),
    );
  }

  /// Most recent (highest id) prompt for the given day. Multiple prompts per
  /// day exist when repeats fire and produce new rows.
  Future<NotificationPromptRow?> promptForDay(DateTime day) {
    final key = dayKey(day);
    return (select(notificationPrompts)
          ..where((p) => p.dayKey.equals(key))
          ..orderBy([(p) => OrderingTerm.desc(p.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<NotificationPromptRow?> promptByPlatformId(int platformId) {
    return (select(notificationPrompts)
          ..where((p) => p.platformId.equals(platformId)))
        .getSingleOrNull();
  }

  Future<List<NotificationPromptRow>> allForDay(DateTime day) {
    final key = dayKey(day);
    return (select(notificationPrompts)
          ..where((p) => p.dayKey.equals(key))
          ..orderBy([(p) => OrderingTerm.asc(p.scheduledFor)]))
        .get();
  }

  Future<int> markShown(int id, DateTime when) {
    return (update(notificationPrompts)..where((p) => p.id.equals(id))).write(
      NotificationPromptsCompanion(shownAt: Value(when)),
    );
  }

  Future<int> markResponded(int id, String response, DateTime when) {
    return (update(notificationPrompts)..where((p) => p.id.equals(id))).write(
      NotificationPromptsCompanion(
        response: Value(response),
        respondedAt: Value(when),
      ),
    );
  }

  Future<int> bumpRepeat(int id) {
    return customUpdate(
      'UPDATE notification_prompts SET repeat_count = repeat_count + 1 WHERE id = ?',
      variables: [Variable.withInt(id)],
      updates: {notificationPrompts},
    );
  }

  Future<List<NotificationPromptRow>> openPromptsBefore(DateTime when) {
    return (select(notificationPrompts)
          ..where((p) => p.respondedAt.isNull() & p.scheduledFor.isSmallerOrEqualValue(when)))
        .get();
  }

  Future<int> deleteOlderThan(DateTime cutoff) {
    return (delete(notificationPrompts)..where((p) => p.dayKey.isSmallerThanValue(dayKey(cutoff)))).go();
  }
}
