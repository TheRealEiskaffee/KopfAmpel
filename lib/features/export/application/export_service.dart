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
import '../../../core/domain/tag_kind.dart';

enum ImportMode { merge, replace }

class ImportResult {
  ImportResult({required this.entriesAdded, required this.tagsAdded});
  final int entriesAdded;
  final int tagsAdded;
}

class ExportService {
  ExportService(this._db);
  final AppDatabase _db;

  static const int kSchemaVersion = 1;

  Future<File> exportJson() async {
    final payload = await _gather();
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    return _writeFile('kopfampel-${_stamp()}.json', json);
  }

  Future<File> exportCsv() async {
    final entries = await _db.select(_db.entries).get();
    final tags = await _db.select(_db.tags).get();
    final entryTagsRows = await _db.select(_db.entryTags).get();
    final tagById = {for (final t in tags) t.id: t};

    final rows = <List<dynamic>>[
      ['date', 'severity', 'note', 'triggers', 'medications', 'createdAt', 'updatedAt'],
    ];
    for (final e in entries) {
      final triggers = entryTagsRows
          .where((et) => et.entryId == e.id)
          .map((et) => tagById[et.tagId])
          .where((t) => t != null && t.kind == TagKind.trigger.value)
          .map((t) => t!.name)
          .join(', ');
      final meds = entryTagsRows
          .where((et) => et.entryId == e.id)
          .map((et) {
            final t = tagById[et.tagId];
            if (t == null || t.kind != TagKind.medication.value) return null;
            return et.dose == null || et.dose!.isEmpty ? t.name : '${t.name}:${et.dose}';
          })
          .where((s) => s != null)
          .join('; ');
      rows.add([
        _dateOnly(e.date),
        e.severity,
        e.note ?? '',
        triggers,
        meds,
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
            _pdfEntryBlock(e, entryTagsRows, tagById, strings),
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
    final entriesIn = (decoded['entries'] as List? ?? const []).cast<Map<String, dynamic>>();
    final tagsIn = (decoded['tags'] as List? ?? const []).cast<Map<String, dynamic>>();

    return _db.transaction(() async {
      if (mode == ImportMode.replace) {
        await _db.delete(_db.entryTags).go();
        await _db.delete(_db.entries).go();
      }

      var tagsAdded = 0;
      final tagIdByKey = <String, int>{};
      final existingTags = await _db.select(_db.tags).get();
      for (final t in existingTags) {
        tagIdByKey['${t.kind}|${t.name}'] = t.id;
      }
      for (final t in tagsIn) {
        final name = (t['name'] as String?)?.trim();
        final kind = (t['kind'] as String?)?.trim();
        if (name == null || name.isEmpty || kind == null) continue;
        final key = '$kind|$name';
        if (tagIdByKey.containsKey(key)) continue;
        final id = await _db.tagsDao.create(
          name: name,
          kind: kind,
          isCustom: (t['isCustom'] as bool?) ?? true,
          color: t['color'] as String?,
        );
        tagIdByKey[key] = id;
        tagsAdded++;
      }

      var entriesAdded = 0;
      for (final e in entriesIn) {
        final dateStr = e['date'] as String?;
        if (dateStr == null) continue;
        final date = dayKey(DateTime.parse(dateStr));

        if (mode == ImportMode.merge) {
          final existing = await _db.entriesDao.findByDate(date);
          if (existing != null) continue;
        }

        final triggerNames = ((e['triggers'] as List?) ?? const []).cast<String>();
        final medications =
            ((e['medications'] as List?) ?? const []).cast<Map<String, dynamic>>();
        final triggerIds = <int>[];
        final medMap = <int, String?>{};
        for (final name in triggerNames) {
          final id = tagIdByKey['${TagKind.trigger.value}|$name'];
          if (id != null) triggerIds.add(id);
        }
        for (final m in medications) {
          final name = m['name'] as String?;
          if (name == null) continue;
          final id = tagIdByKey['${TagKind.medication.value}|$name'];
          if (id != null) medMap[id] = m['dose'] as String?;
        }

        await _db.entriesDao.upsert(
          date: date,
          severity: (e['severity'] as String?) ?? Severity.none.value,
          note: e['note'] as String?,
          triggerTagIds: triggerIds,
          medicationTagIdsToDose: medMap,
        );
        entriesAdded++;
      }
      return ImportResult(entriesAdded: entriesAdded, tagsAdded: tagsAdded);
    });
  }

  Future<Map<String, dynamic>> _gather() async {
    final entries = await _db.select(_db.entries).get();
    final tags = await _db.select(_db.tags).get();
    final entryTagsRows = await _db.select(_db.entryTags).get();
    final tagById = {for (final t in tags) t.id: t};

    return {
      'schemaVersion': kSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tags': tags
          .map((t) => {
                'name': t.name,
                'kind': t.kind,
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
          'triggers': ets
              .map((et) => tagById[et.tagId])
              .where((t) => t != null && t.kind == TagKind.trigger.value)
              .map((t) => t!.name)
              .toList(),
          'medications': ets
              .map((et) {
                final t = tagById[et.tagId];
                if (t == null || t.kind != TagKind.medication.value) return null;
                return {'name': t.name, 'dose': et.dose};
              })
              .where((m) => m != null)
              .toList(),
          'createdAt': e.createdAt.toIso8601String(),
          'updatedAt': e.updatedAt.toIso8601String(),
        };
      }).toList(),
    };
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
    PdfStrings strings,
  ) {
    final sev = Severity.fromString(e.severity);
    final color = switch (sev) {
      Severity.green => PdfColors.green600,
      Severity.yellow => PdfColors.amber600,
      Severity.red => PdfColors.red700,
      Severity.none => PdfColors.grey400,
    };
    final triggers = entryTagsRows
        .where((et) => et.entryId == e.id)
        .map((et) => tagById[et.tagId])
        .where((t) => t != null && t.kind == TagKind.trigger.value)
        .map((t) => t!.name)
        .join(', ');
    final meds = entryTagsRows
        .where((et) => et.entryId == e.id)
        .map((et) {
          final t = tagById[et.tagId];
          if (t == null || t.kind != TagKind.medication.value) return null;
          return et.dose == null || et.dose!.isEmpty ? t.name : '${t.name} (${et.dose})';
        })
        .where((s) => s != null)
        .join(', ');

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
          if (triggers.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                '${strings.triggersLabel}: $triggers',
                style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
              ),
            ),
          if (meds.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                '${strings.medicationsLabel}: $meds',
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
    required this.triggersLabel,
    required this.medicationsLabel,
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
  final String triggersLabel;
  final String medicationsLabel;
  final String footer;
  final List<String> monthNames;
}
