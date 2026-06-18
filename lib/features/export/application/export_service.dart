import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/database/app_database.dart';
import '../../../core/database/converters.dart';
import '../../../core/domain/severity.dart';

enum ImportMode { merge, replace }

class ImportResult {
  ImportResult({required this.entriesAdded, required this.tagsAdded});
  final int entriesAdded;
  final int tagsAdded;
}

class ExportService {
  ExportService(this._db);
  final AppDatabase _db;

  static const int kSchemaVersion = 2;

  Future<File> exportJson() async {
    final payload = await _gather();
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    return _writeFile('kopfampel-${_stamp()}.json', json);
  }

  Future<File> exportCsv() async {
    final entries = await _db.select(_db.entries).get();
    final categories = await _sortedCategories();
    final tags = await _db.select(_db.tags).get();
    final entryTagsRows = await _db.select(_db.entryTags).get();
    final tagById = {for (final t in tags) t.id: t};

    final rows = <List<dynamic>>[
      ['date', 'severity', 'note', 'tags', 'createdAt', 'updatedAt'],
    ];
    for (final e in entries) {
      final tagIds = entryTagsRows
          .where((et) => et.entryId == e.id)
          .map((et) => et.tagId)
          .toSet();
      rows.add([
        _dateOnly(e.date),
        e.severity,
        e.note ?? '',
        _groupTagsByCategory(categories, tagById, tagIds, separator: '; '),
        e.createdAt.toIso8601String(),
        e.updatedAt.toIso8601String(),
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    return _writeFile('kopfampel-${_stamp()}.csv', csv);
  }

  /// Monthly report; if [month] is null, includes all entries.
  Future<File> exportPdf({
    required PdfStrings strings,
    DateTime? month,
  }) async {
    final allEntries = await _db.select(_db.entries).get();
    final selected = month == null
        ? allEntries
        : allEntries.where((e) {
            return e.date.year == month.year && e.date.month == month.month;
          }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final categories = await _sortedCategories();
    final tags = await _db.select(_db.tags).get();
    final entryTagsRows = await _db.select(_db.entryTags).get();
    final tagById = {for (final t in tags) t.id: t};

    final counts = <Severity, int>{
      for (final s in Severity.values) s: 0,
    };
    for (final e in selected) {
      final sev = Severity.fromString(e.severity);
      counts[sev] = (counts[sev] ?? 0) + 1;
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(strings.title, style: const pw.TextStyle(fontSize: 22)),
                pw.SizedBox(height: 4),
                pw.Text(
                  month == null
                      ? strings.allTimeHeading
                      : '${_monthName(month.month, strings.monthNames)} ${month.year}',
                  style: pw.TextStyle(color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Header(level: 1, text: strings.statsHeading),
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _statChip('${strings.statsTotal}: ${selected.length}', PdfColors.grey700),
                _statChip('${strings.statsNone}: ${counts[Severity.none] ?? 0}', PdfColors.grey400),
                _statChip('${strings.statsGreen}: ${counts[Severity.green] ?? 0}', PdfColors.green600),
                _statChip('${strings.statsYellow}: ${counts[Severity.yellow] ?? 0}', PdfColors.amber600),
                _statChip('${strings.statsRed}: ${counts[Severity.red] ?? 0}', PdfColors.red700),
              ],
            ),
          ),
          pw.Header(level: 1, text: strings.entriesHeading),
          if (selected.isEmpty)
            pw.Text(strings.allTimeHeading, style: pw.TextStyle(color: PdfColors.grey700)),
          for (final e in selected)
            _pdfEntryBlock(e, entryTagsRows, tagById, categories),
        ],
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            '${strings.footer} · ${ctx.pageNumber}/${ctx.pagesCount}',
            style: pw.TextStyle(color: PdfColors.grey500, fontSize: 9),
          ),
        ),
      ),
    );

    final bytes = await doc.save();
    final suffix = month == null
        ? 'all'
        : '${month.year}-${month.month.toString().padLeft(2, '0')}';
    return _writeBytes('kopfampel-report-$suffix.pdf', bytes);
  }

  Future<ImportResult> importJson(File file, ImportMode mode) async {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final hasCategories = decoded['categories'] is List;

    final categoriesIn =
        (decoded['categories'] as List? ?? const []).cast<Map<String, dynamic>>();
    final tagsIn = (decoded['tags'] as List? ?? const []).cast<Map<String, dynamic>>();
    final entriesIn = (decoded['entries'] as List? ?? const []).cast<Map<String, dynamic>>();

    return _db.transaction(() async {
      if (mode == ImportMode.replace) {
        await _db.delete(_db.entryTags).go();
        await _db.delete(_db.entries).go();
      }

      // --- Categories ----------------------------------------------------
      final catIdByName = <String, int>{};
      for (final c in await _db.select(_db.categories).get()) {
        catIdByName[c.name] = c.id;
      }

      Future<int> ensureCategory(
        String name, {
        String? icon,
        String? color,
        int sortOrder = 0,
        bool isCustom = true,
      }) async {
        final existing = catIdByName[name];
        if (existing != null) return existing;
        final id = await _db.categoriesDao.create(
          name: name,
          icon: icon,
          color: color,
          sortOrder: sortOrder,
          isCustom: isCustom,
        );
        catIdByName[name] = id;
        return id;
      }

      // --- Tags ----------------------------------------------------------
      var tagsAdded = 0;
      final tagIdByKey = <String, int>{}; // '$categoryId|$name'
      for (final t in await _db.select(_db.tags).get()) {
        tagIdByKey['${t.categoryId}|${t.name}'] = t.id;
      }

      Future<int> ensureTag(
        int categoryId,
        String name, {
        bool isCustom = true,
        String? color,
      }) async {
        final key = '$categoryId|$name';
        final existing = tagIdByKey[key];
        if (existing != null) return existing;
        final id = await _db.tagsDao.create(
          name: name,
          categoryId: categoryId,
          isCustom: isCustom,
          color: color,
        );
        tagIdByKey[key] = id;
        tagsAdded++;
        return id;
      }

      // Maps a tag reference (category name + tag name) to its id, or null.
      Future<int?> resolveTag(String? categoryName, String? name) async {
        if (categoryName == null || name == null || name.isEmpty) return null;
        final catId = catIdByName[categoryName];
        if (catId == null) return null;
        return ensureTag(catId, name);
      }

      // Legacy v1 export maps the hard-coded kinds onto two categories.
      var legacyTriggerCat = 0;
      var legacyMedCat = 0;
      if (!hasCategories) {
        legacyTriggerCat =
            await ensureCategory('Trigger', icon: 'bolt', sortOrder: 0, isCustom: false);
        legacyMedCat =
            await ensureCategory('Medikamente', icon: 'bandage', sortOrder: 1, isCustom: false);
      }

      if (hasCategories) {
        for (final c in categoriesIn) {
          final name = (c['name'] as String?)?.trim();
          if (name == null || name.isEmpty) continue;
          await ensureCategory(
            name,
            icon: c['icon'] as String?,
            color: c['color'] as String?,
            sortOrder: (c['sortOrder'] as int?) ?? 0,
            isCustom: (c['isCustom'] as bool?) ?? true,
          );
        }
        for (final t in tagsIn) {
          final name = (t['name'] as String?)?.trim();
          final categoryName = (t['category'] as String?)?.trim();
          if (name == null || name.isEmpty || categoryName == null) continue;
          final catId = catIdByName[categoryName];
          if (catId == null) continue;
          await ensureTag(
            catId,
            name,
            isCustom: (t['isCustom'] as bool?) ?? true,
            color: t['color'] as String?,
          );
        }
      } else {
        // Legacy tags carry a `kind` ('trigger' | 'medication').
        for (final t in tagsIn) {
          final name = (t['name'] as String?)?.trim();
          final kind = (t['kind'] as String?)?.trim();
          if (name == null || name.isEmpty) continue;
          final catId = kind == 'medication' ? legacyMedCat : legacyTriggerCat;
          await ensureTag(
            catId,
            name,
            isCustom: (t['isCustom'] as bool?) ?? true,
            color: t['color'] as String?,
          );
        }
      }

      // --- Entries -------------------------------------------------------
      var entriesAdded = 0;
      for (final e in entriesIn) {
        final dateStr = e['date'] as String?;
        if (dateStr == null) continue;
        final date = dayKey(DateTime.parse(dateStr));

        if (mode == ImportMode.merge) {
          final existing = await _db.entriesDao.findByDate(date);
          if (existing != null) continue;
        }

        final tagIds = <int>[];
        if (hasCategories) {
          final refs = ((e['tags'] as List?) ?? const []).cast<Map<String, dynamic>>();
          for (final ref in refs) {
            final id = await resolveTag(ref['category'] as String?, ref['name'] as String?);
            if (id != null) tagIds.add(id);
          }
        } else {
          final triggerNames = ((e['triggers'] as List?) ?? const []).cast<String>();
          for (final name in triggerNames) {
            tagIds.add(await ensureTag(legacyTriggerCat, name));
          }
          final medications =
              ((e['medications'] as List?) ?? const []).cast<Map<String, dynamic>>();
          for (final m in medications) {
            final name = (m['name'] as String?)?.trim();
            if (name == null || name.isEmpty) continue;
            tagIds.add(await ensureTag(legacyMedCat, name));
          }
        }

        await _db.entriesDao.upsert(
          date: date,
          severity: (e['severity'] as String?) ?? Severity.none.value,
          note: e['note'] as String?,
          tagIds: tagIds,
        );
        entriesAdded++;
      }
      return ImportResult(entriesAdded: entriesAdded, tagsAdded: tagsAdded);
    });
  }

  Future<Map<String, dynamic>> _gather() async {
    final categories = await _sortedCategories();
    final entries = await _db.select(_db.entries).get();
    final tags = await _db.select(_db.tags).get();
    final entryTagsRows = await _db.select(_db.entryTags).get();
    final tagById = {for (final t in tags) t.id: t};
    final categoryNameById = {for (final c in categories) c.id: c.name};

    return {
      'schemaVersion': kSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories
          .map((c) => {
                'name': c.name,
                'icon': c.icon,
                'color': c.color,
                'sortOrder': c.sortOrder,
                'isCustom': c.isCustom,
              })
          .toList(),
      'tags': tags
          .map((t) => {
                'name': t.name,
                'category': categoryNameById[t.categoryId],
                'isCustom': t.isCustom,
                'color': t.color,
              })
          .toList(),
      'entries': entries.map((e) {
        final ets = entryTagsRows.where((et) => et.entryId == e.id);
        return {
          'date': _dateOnly(e.date),
          'severity': e.severity,
          'note': e.note,
          'tags': ets
              .map((et) => tagById[et.tagId])
              .where((t) => t != null)
              .map((t) => {
                    'category': categoryNameById[t!.categoryId],
                    'name': t.name,
                  })
              .toList(),
          'createdAt': e.createdAt.toIso8601String(),
          'updatedAt': e.updatedAt.toIso8601String(),
        };
      }).toList(),
    };
  }

  Future<List<CategoryRow>> _sortedCategories() async {
    final rows = await _db.select(_db.categories).get();
    rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return rows;
  }

  /// Builds a human-readable "Category: a, b; Category2: c" string for one
  /// entry's tag set, in category display order.
  String _groupTagsByCategory(
    List<CategoryRow> categories,
    Map<int, TagRow> tagById,
    Set<int> tagIds, {
    required String separator,
  }) {
    final namesByCategory = <int, List<String>>{};
    for (final id in tagIds) {
      final t = tagById[id];
      if (t == null) continue;
      namesByCategory.putIfAbsent(t.categoryId, () => []).add(t.name);
    }
    final parts = <String>[];
    for (final c in categories) {
      final names = namesByCategory[c.id];
      if (names == null || names.isEmpty) continue;
      names.sort();
      parts.add('${c.name}: ${names.join(', ')}');
    }
    return parts.join(separator);
  }

  Future<File> _writeFile(String name, String contents) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsString(contents);
    return file;
  }

  Future<File> _writeBytes(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes);
    return file;
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _stamp() => DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;

  static String _monthName(int month, List<String> names) => names[month - 1];

  pw.Widget _statChip(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Text(text, style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
    );
  }

  pw.Widget _pdfEntryBlock(
    EntryRow e,
    List<EntryTagRow> entryTagsRows,
    Map<int, TagRow> tagById,
    List<CategoryRow> categories,
  ) {
    final sev = Severity.fromString(e.severity);
    final color = switch (sev) {
      Severity.green => PdfColors.green600,
      Severity.yellow => PdfColors.amber600,
      Severity.red => PdfColors.red700,
      Severity.none => PdfColors.grey400,
    };

    final tagIds = entryTagsRows
        .where((et) => et.entryId == e.id)
        .map((et) => et.tagId)
        .toSet();
    final namesByCategory = <int, List<String>>{};
    for (final id in tagIds) {
      final t = tagById[id];
      if (t == null) continue;
      namesByCategory.putIfAbsent(t.categoryId, () => []).add(t.name);
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: color, width: 4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _dateOnly(e.date),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  e.severity,
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 9),
                ),
              ),
            ],
          ),
          if (e.note != null && e.note!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(e.note!),
            ),
          for (final c in categories)
            if (namesByCategory[c.id] != null && namesByCategory[c.id]!.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  '${c.name}: ${(namesByCategory[c.id]!..sort()).join(', ')}',
                  style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                ),
              ),
        ],
      ),
    );
  }
}

/// Plain Dart record for PDF localization strings.
class PdfStrings {
  const PdfStrings({
    required this.title,
    required this.allTimeHeading,
    required this.statsHeading,
    required this.statsTotal,
    required this.statsNone,
    required this.statsGreen,
    required this.statsYellow,
    required this.statsRed,
    required this.entriesHeading,
    required this.footer,
    required this.monthNames,
  });

  final String title;
  final String allTimeHeading;
  final String statsHeading;
  final String statsTotal;
  final String statsNone;
  final String statsGreen;
  final String statsYellow;
  final String statsRed;
  final String entriesHeading;
  final String footer;
  final List<String> monthNames;
}
