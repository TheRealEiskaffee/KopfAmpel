import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/database_providers.dart';
import 'database/seeders/default_categories.dart';

/// One-shot startup work: seeds default categories + tags on first launch.
/// Subsequent launches are no-ops because the seeder checks for existing rows.
final bootstrapProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final settings = await ref.watch(settingsDaoProvider).get();
  await DefaultCategories.seedIfEmpty(db, locale: settings.locale ?? 'de');
});
