import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopfampel/core/database/app_database.dart';
import 'package:kopfampel/core/database/seeders/default_categories.dart';
import 'package:kopfampel/core/database/tables/app_settings.dart';
import 'package:kopfampel/core/domain/severity.dart';

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
      expect(settings.maxRepeatsPerDay, kAlwaysRepeats);
      expect(settings.notificationsEnabled, true);
      expect(settings.onboardingComplete, false);
    });
  });

  group('DefaultCategories seeder', () {
    test('seeds the predefined categories with their tags when empty', () async {
      await DefaultCategories.seedIfEmpty(db, locale: 'de');
      final cats = await db.categoriesDao.all();
      final expected = DefaultCategories.forLocale('de');
      expect(cats.length, expected.length);

      final totalExpectedTags =
          expected.fold<int>(0, (sum, c) => sum + c.tags.length);
      final allTags = await db.tagsDao.all();
      expect(allTags.length, totalExpectedTags);
      expect(allTags.first.isCustom, false);
    });

    test('seeder is idempotent', () async {
      await DefaultCategories.seedIfEmpty(db, locale: 'de');
      await DefaultCategories.seedIfEmpty(db, locale: 'de');
      final cats = await db.categoriesDao.all();
      expect(cats.length, DefaultCategories.forLocale('de').length);
    });

    test('insertIfMissing dedupes by (name, categoryId)', () async {
      final catId = await db.categoriesDao.create(name: 'Trigger', isCustom: false);
      await db.tagsDao.create(name: 'Stress', categoryId: catId);
      final result = await db.tagsDao.insertIfMissing(
        name: 'Stress',
        categoryId: catId,
      );
      expect(result, isNull);
    });
  });

  group('CategoriesDao', () {
    test('deleting a category cascades to its tags', () async {
      final catId = await db.categoriesDao.create(name: 'Trigger');
      await db.tagsDao.create(name: 'Stress', categoryId: catId);
      await db.tagsDao.create(name: 'Wetter', categoryId: catId);
      expect((await db.tagsDao.all()).length, 2);

      await db.categoriesDao.deleteById(catId);
      expect(await db.tagsDao.all(), isEmpty);
    });
  });

  group('EntriesDao', () {
    test('upsert inserts a new entry, then updates the same date in place', () async {
      final catId = await db.categoriesDao.create(name: 'Trigger');
      final tagA = await db.tagsDao.create(name: 'Stress', categoryId: catId);
      final tagB = await db.tagsDao.create(name: 'Ibuprofen', categoryId: catId);

      final today = DateTime(2026, 6, 17);

      final firstId = await db.entriesDao.upsert(
        date: today,
        severity: Severity.yellow.value,
        note: 'morgens leicht',
        tagIds: [tagA, tagB],
      );

      final loaded = await db.entriesDao.findByDate(today);
      expect(loaded, isNotNull);
      expect(loaded!.entry.id, firstId);
      expect(loaded.entry.severity, Severity.yellow.value);
      expect(loaded.entry.note, 'morgens leicht');
      expect(loaded.tags.length, 2);

      // Second upsert overwrites severity, note, and tag set.
      final secondId = await db.entriesDao.upsert(
        date: today,
        severity: Severity.red.value,
        note: null,
        tagIds: const [],
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
        tagIds: const [],
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

    test('re-inserting the same platformId keeps a single, current row', () async {
      // rescheduleHorizon re-seeds the horizon on every app resume, so the same
      // platformId is inserted repeatedly. Each insert must replace the prior
      // row — otherwise promptByPlatformId matches many rows and throws, and the
      // notification action silently fails to log an entry.
      final day = DateTime(2026, 6, 17);
      await db.notificationPromptsDao.insertPrompt(
        dayKey: day,
        scheduledFor: DateTime(2026, 6, 17, 9),
        platformId: 99,
      );
      await db.notificationPromptsDao.insertPrompt(
        dayKey: day,
        scheduledFor: DateTime(2026, 6, 17, 14),
        platformId: 99,
      );

      final all = await db.notificationPromptsDao.allForDay(day);
      expect(all.where((p) => p.platformId == 99).length, 1);

      final row = await db.notificationPromptsDao.promptByPlatformId(99);
      expect(row, isNotNull);
      expect(row!.scheduledFor, DateTime(2026, 6, 17, 14));
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
