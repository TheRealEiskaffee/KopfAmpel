import '../app_database.dart';

class SeedCategory {
  const SeedCategory({required this.name, required this.icon, required this.tags});
  final String name;
  final String icon;
  final List<String> tags;
}

/// Predefined categories + tags installed on first launch. All of these are
/// `isCustom: false` but fully editable and deletable by the user.
class DefaultCategories {
  const DefaultCategories._();

  static List<SeedCategory> forLocale(String locale) {
    final en = locale.startsWith('en');
    return [
      SeedCategory(
        name: en ? 'Triggers' : 'Trigger',
        icon: 'bolt',
        tags: en
            ? const [
                'Stress',
                'Lack of sleep',
                'Weather',
                'Hormonal',
                'Screen time',
                'Dehydration',
                'Caffeine',
                'Alcohol',
                'Diet',
                'Eye strain',
              ]
            : const [
                'Stress',
                'Schlafmangel',
                'Wetter',
                'Hormonell',
                'Bildschirmzeit',
                'Dehydration',
                'Koffein',
                'Alkohol',
                'Ernährung',
                'Augenbelastung',
              ],
      ),
      SeedCategory(
        name: en ? 'Medication' : 'Medikamente',
        icon: 'bandage',
        tags: en ? const ['Ibuprofen', 'Paracetamol', 'Aspirin'] : const ['Ibuprofen', 'Paracetamol', 'ASS'],
      ),
      SeedCategory(
        name: en ? 'General' : 'Allgemein',
        icon: 'sparkles',
        tags: en
            ? const ['Menstruation', 'Travel', 'Illness', 'Sport']
            : const ['Menstruation', 'Reise', 'Krankheit', 'Sport'],
      ),
    ];
  }

  static Future<void> seedIfEmpty(AppDatabase db, {required String locale}) async {
    final existing = await db.categoriesDao.all();
    if (existing.isNotEmpty) return;

    final cats = forLocale(locale);
    for (var i = 0; i < cats.length; i++) {
      final c = cats[i];
      final categoryId = await db.categoriesDao.create(
        name: c.name,
        icon: c.icon,
        sortOrder: i,
        isCustom: false,
      );
      for (final tagName in c.tags) {
        await db.tagsDao.create(name: tagName, categoryId: categoryId, isCustom: false);
      }
    }
  }
}
