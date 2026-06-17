import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopfampel/core/database/app_database.dart';
import 'package:kopfampel/core/database/seeders/default_tags.dart';
import 'package:kopfampel/core/domain/severity.dart';
import 'package:kopfampel/core/domain/tag_kind.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SettingsDao', () {
    test('returns seeded singleton row with sane defaults', () async {
      final settings = await db.settingsDao.get();
      expect(settings.id, 0);
      expect(settings.windowStartMinutes, 18 * 60);
      expect(settings.windowEndMinutes, 22 * 60);
      expect(settings.repeatEnabled, true);
      expect(settings.maxRepeatsPerDay, 3);
      expect(settings.notificationsEnabled, true);
      expect(settings.onboardingComplete, false);
    });
  });

  group('TagsDao + DefaultTags seeder', () {
    test('seeds German triggers and medications when empty', () async {
      await DefaultTags.seedIfEmpty(db, locale: 'de');
      final triggers = await db.tagsDao.watchByKind(TagKind.trigger.value).first;
      final meds = await db.tagsDao.watchByKind(TagKind.medication.value).first;

      expect(triggers.length, DefaultTags.triggers('de').length);
      expect(meds.length, DefaultTags.medications('de').length);
      expect(triggers.first.isCustom, false);
    });

    test('seeder is idempotent', () async {
      await DefaultTags.seedIfEmpty(db, locale: 'de');
      await DefaultTags.seedIfEmpty(db, locale: 'de');
      final all = await db.tagsDao.all();
      expect(
        all.length,
        DefaultTags.triggers('de').length + DefaultTags.medications('de').length,
      );
    });

    test('insertIfMissing dedupes by (name, kind)', () async {
      await db.tagsDao.create(name: 'Stress', kind: TagKind.trigger.value);
      final result = await db.tagsDao.insertIfMissing(
        name: 'Stress',
        kind: TagKind.trigger.value,
      );
      expect(result, isNull);
    });
  });

  group('EntriesDao', () {
    test('upsert inserts a new entry, then updates the same date in place', () async {
      final triggerId = await db.tagsDao.create(
        name: 'Stress',
        kind: TagKind.trigger.value,
      );
      final medId = await db.tagsDao.create(
        name: 'Ibuprofen',
        kind: TagKind.medication.value,
      );

      final today = DateTime(2026, 6, 17);

      final firstId = await db.entriesDao.upsert(
        date: today,
        severity: Severity.yellow.value,
        note: 'morgens leicht',
        triggerTagIds: [triggerId],
        medicationTagIdsToDose: {medId: '400mg'},
      );

      final loaded = await db.entriesDao.findByDate(today);
      expect(loaded, isNotNull);
      expect(loaded!.entry.id, firstId);
      expect(loaded.entry.severity, Severity.yellow.value);
      expect(loaded.entry.note, 'morgens leicht');
      expect(loaded.tags.length, 2);
      expect(loaded.doses[medId], '400mg');

      // Second upsert overwrites severity, note, and tag set.
      final secondId = await db.entriesDao.upsert(
        date: today,
        severity: Severity.red.value,
        note: null,
        triggerTagIds: const [],
        medicationTagIdsToDose: const {},
      );
      expect(secondId, firstId, reason: 'second upsert must keep the same row');

      final reloaded = await db.entriesDao.findByDate(today);
      expect(reloaded!.entry.severity, Severity.red.value);
      expect(reloaded.entry.note, isNull);
      expect(reloaded.tags, isEmpty);
    });

    test('deleteByDate removes the entry', () async {
      final today = DateTime(2026, 6, 17);
      await db.entriesDao.upsert(
        date: today,
        severity: Severity.green.value,
        triggerTagIds: const [],
        medicationTagIdsToDose: const {},
      );
      expect(await db.entriesDao.findByDate(today), isNotNull);

      await db.entriesDao.deleteByDate(today);
      expect(await db.entriesDao.findByDate(today), isNull);
    });
  });

  group('NotificationPromptsDao', () {
    test('insert, mark shown, mark responded — end-to-end happy path', () async {
      final day = DateTime(2026, 6, 17);
      final scheduled = DateTime(2026, 6, 17, 19, 23);

      final id = await db.notificationPromptsDao.insertPrompt(
        dayKey: day,
        scheduledFor: scheduled,
        platformId: 42,
      );

      await db.notificationPromptsDao.markShown(id, scheduled);
      await db.notificationPromptsDao.markResponded(id, 'yes', scheduled);

      final row = await db.notificationPromptsDao.promptForDay(day);
      expect(row, isNotNull);
      expect(row!.response, 'yes');
      expect(row.respondedAt, scheduled);
    });

    test('openPromptsBefore returns unresponded prompts with past scheduledFor', () async {
      final day = DateTime(2026, 6, 17);
      final past = DateTime(2026, 6, 17, 8);
      final future = DateTime(2026, 6, 18, 8);

      await db.notificationPromptsDao.insertPrompt(
        dayKey: day,
        scheduledFor: past,
        platformId: 1,
      );
      await db.notificationPromptsDao.insertPrompt(
        dayKey: day.add(const Duration(days: 1)),
        scheduledFor: future,
        platformId: 2,
      );

      final open = await db.notificationPromptsDao.openPromptsBefore(
        DateTime(2026, 6, 17, 12),
      );
      expect(open.length, 1);
      expect(open.first.platformId, 1);
    });

    test('bumpRepeat increments repeat count', () async {
      final day = DateTime(2026, 6, 17);
      final id = await db.notificationPromptsDao.insertPrompt(
        dayKey: day,
        scheduledFor: day,
        platformId: 7,
      );
      await db.notificationPromptsDao.bumpRepeat(id);
      await db.notificationPromptsDao.bumpRepeat(id);

      final row = await db.notificationPromptsDao.promptForDay(day);
      expect(row!.repeatCount, 2);
    });
  });
}
