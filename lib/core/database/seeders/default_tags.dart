import '../../domain/tag_kind.dart';
import '../app_database.dart';

class DefaultTags {
  const DefaultTags._();

  static List<String> triggers(String locale) {
    if (locale.startsWith('en')) {
      return const [
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
      ];
    }
    return const [
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
    ];
  }

  static List<String> medications(String locale) {
    if (locale.startsWith('en')) {
      return const ['Ibuprofen', 'Paracetamol', 'Aspirin'];
    }
    return const ['Ibuprofen', 'Paracetamol', 'ASS'];
  }

  static Future<void> seedIfEmpty(AppDatabase db, {required String locale}) async {
    final tagsDao = db.tagsDao;
    final existing = await tagsDao.all();
    if (existing.isNotEmpty) return;

    for (final name in triggers(locale)) {
      await tagsDao.create(name: name, kind: TagKind.trigger.value, isCustom: false);
    }
    for (final name in medications(locale)) {
      await tagsDao.create(name: name, kind: TagKind.medication.value, isCustom: false);
    }
  }
}
