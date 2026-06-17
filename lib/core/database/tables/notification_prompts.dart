import 'package:drift/drift.dart';

@DataClassName('NotificationPromptRow')
class NotificationPrompts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Day the prompt belongs to (midnight local).
  DateTimeColumn get dayKey => dateTime()();

  DateTimeColumn get scheduledFor => dateTime()();
  DateTimeColumn get shownAt => dateTime().nullable()();
  DateTimeColumn get respondedAt => dateTime().nullable()();

  /// 'yes' | 'no' | 'ignored' | 'missed'.
  TextColumn get response => text().nullable()();

  IntColumn get repeatCount => integer().withDefault(const Constant(0))();

  /// Platform notification id used when scheduling — needed to cancel pending repeats.
  IntColumn get platformId => integer().unique()();
}
