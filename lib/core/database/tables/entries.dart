import 'package:drift/drift.dart';

@DataClassName('EntryRow')
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stored at midnight (00:00:00) in the local time zone — one row per day.
  DateTimeColumn get date => dateTime().unique()();

  /// Severity bucket: 'none' | 'green' | 'yellow' | 'red'.
  TextColumn get severity => text().withLength(min: 3, max: 16)();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
