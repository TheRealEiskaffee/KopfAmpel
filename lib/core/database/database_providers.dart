import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/category.dart';
import '../domain/entry.dart';
import '../domain/severity.dart';
import '../domain/tag.dart';
import 'app_database.dart';
import 'daos/categories_dao.dart';
import 'daos/entries_dao.dart';
import 'daos/notification_prompts_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/tags_dao.dart';

/// Singleton database. Disposed when the ProviderScope dies.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final entriesDaoProvider = Provider<EntriesDao>((ref) {
  return ref.watch(appDatabaseProvider).entriesDao;
});

final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  return ref.watch(appDatabaseProvider).categoriesDao;
});

final tagsDaoProvider = Provider<TagsDao>((ref) {
  return ref.watch(appDatabaseProvider).tagsDao;
});

final notificationPromptsDaoProvider = Provider<NotificationPromptsDao>((ref) {
  return ref.watch(appDatabaseProvider).notificationPromptsDao;
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return ref.watch(appDatabaseProvider).settingsDao;
});

final settingsProvider = StreamProvider<AppSettingsRow>((ref) {
  return ref.watch(settingsDaoProvider).watch();
});

Category _categoryFromRow(dynamic row) {
  return Category(
    id: row.id as int,
    name: row.name as String,
    icon: row.icon as String?,
    color: row.color as String?,
    sortOrder: row.sortOrder as int,
    isCustom: row.isCustom as bool,
  );
}

Tag _tagFromRow(dynamic row) {
  return Tag(
    id: row.id as int,
    name: row.name as String,
    categoryId: row.categoryId as int,
    isCustom: row.isCustom as bool,
    color: row.color as String?,
  );
}

/// All categories, ordered by sortOrder then name. Drives the entry sheet,
/// the management screen and the stats grouping.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.watchAll().map((rows) => rows.map(_categoryFromRow).toList());
});

/// Tags belonging to a single category, alphabetically sorted.
final tagsByCategoryProvider = StreamProvider.family<List<Tag>, int>((ref, categoryId) {
  final dao = ref.watch(tagsDaoProvider);
  return dao.watchByCategory(categoryId).map(
        (rows) => rows.map(_tagFromRow).toList(),
      );
});

class EntriesRepository {
  EntriesRepository(this._dao);
  final EntriesDao _dao;

  Future<HeadacheEntry?> findByDate(DateTime date) async {
    final result = await _dao.findByDate(date);
    if (result == null) return null;
    return _toDomain(result);
  }

  Future<int> upsert({
    required DateTime date,
    required Severity severity,
    String? note,
    required List<Tag> tags,
  }) {
    return _dao.upsert(
      date: date,
      severity: severity.value,
      note: note,
      tagIds: tags.map((t) => t.id).toList(),
    );
  }

  Future<void> deleteByDate(DateTime date) => _dao.deleteByDate(date);

  HeadacheEntry _toDomain(EntryWithTags result) {
    return HeadacheEntry(
      id: result.entry.id,
      date: result.entry.date,
      severity: Severity.fromString(result.entry.severity),
      note: result.entry.note,
      tags: result.tags.map(_tagFromRow).toList(),
      createdAt: result.entry.createdAt,
      updatedAt: result.entry.updatedAt,
    );
  }
}

final entriesRepositoryProvider = Provider<EntriesRepository>((ref) {
  return EntriesRepository(ref.watch(entriesDaoProvider));
});
