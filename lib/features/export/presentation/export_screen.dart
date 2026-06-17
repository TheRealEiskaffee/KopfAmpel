import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/i18n/app_localizations.dart';
import '../application/export_providers.dart';
import '../application/export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _busy = false;
  DateTime _pdfMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _pdfAllTime = false;

  Future<void> _withBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(File file, String subject) async {
    // sharePositionOrigin is required on iPad and harmless elsewhere; it lets
    // the share sheet anchor itself when presented as a popover.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
      sharePositionOrigin: origin,
    );
  }

  Future<void> _runExport(Future<File> Function() build, String subject) async {
    final l10n = AppLocalizations.of(context);
    await _withBusy(() async {
      try {
        final file = await build();
        if (!mounted) return;
        await _share(file, subject);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e.toString()))),
        );
      }
    });
  }

  Future<void> _exportJson() => _runExport(
        () => ref.read(exportServiceProvider).exportJson(),
        AppLocalizations.of(context).exportJson,
      );

  Future<void> _exportCsv() => _runExport(
        () => ref.read(exportServiceProvider).exportCsv(),
        AppLocalizations.of(context).exportCsv,
      );

  Future<void> _exportPdf() {
    final strings = pdfStringsOf(context);
    final month = _pdfAllTime ? null : _pdfMonth;
    return _runExport(
      () => ref.read(exportServiceProvider).exportPdf(
            strings: strings,
            month: month,
          ),
      AppLocalizations.of(context).exportPdf,
    );
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    if (!mounted) return;
    final mode = await showDialog<ImportMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.importModeTitle),
        children: [
          _ImportModeOption(
            title: l10n.importModeMerge,
            subtitle: l10n.importModeMergeDescription,
            mode: ImportMode.merge,
          ),
          _ImportModeOption(
            title: l10n.importModeReplace,
            subtitle: l10n.importModeReplaceDescription,
            mode: ImportMode.replace,
            destructive: true,
          ),
        ],
      ),
    );
    if (mode == null) return;

    await _withBusy(() async {
      try {
        final file = File(result.files.single.path!);
        final import = await ref.read(exportServiceProvider).importJson(file, mode);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importDone(import.entriesAdded))),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importFailed(e.toString()))),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthLabel = DateFormat.yMMMM(locale).format(_pdfMonth);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportTitle)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _Section(
                title: l10n.exportSection,
                children: [
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: Text(l10n.exportJson),
                    subtitle: Text(l10n.exportJsonDescription),
                    trailing: const Icon(Icons.ios_share),
                    onTap: _busy ? null : _exportJson,
                  ),
                  ListTile(
                    leading: const Icon(Icons.table_chart_outlined),
                    title: Text(l10n.exportCsv),
                    subtitle: Text(l10n.exportCsvDescription),
                    trailing: const Icon(Icons.ios_share),
                    onTap: _busy ? null : _exportCsv,
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      l10n.exportPdf,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      l10n.exportPdfDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  SwitchListTile(
                    title: Text(l10n.exportPdfAllTime),
                    value: _pdfAllTime,
                    onChanged: (v) => setState(() => _pdfAllTime = v),
                  ),
                  if (!_pdfAllTime)
                    ListTile(
                      title: Text(monthLabel),
                      leading: const Icon(Icons.calendar_month_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _pdfMonth,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialEntryMode: DatePickerEntryMode.calendarOnly,
                        );
                        if (picked != null) {
                          setState(() => _pdfMonth = DateTime(picked.year, picked.month));
                        }
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(l10n.exportPdf),
                    ),
                  ),
                ],
              ),
              _Section(
                title: l10n.importSection,
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined),
                    title: Text(l10n.importJson),
                    subtitle: Text(l10n.importJsonDescription),
                    onTap: _busy ? null : _import,
                  ),
                ],
              ),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(l10n.exporting),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ImportModeOption extends StatelessWidget {
  const _ImportModeOption({
    required this.title,
    required this.subtitle,
    required this.mode,
    this.destructive = false,
  });

  final String title;
  final String subtitle;
  final ImportMode mode;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return InkWell(
      onTap: () => Navigator.of(context).pop(mode),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
