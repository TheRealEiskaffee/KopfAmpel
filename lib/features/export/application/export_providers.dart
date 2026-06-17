import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/i18n/app_localizations.dart';
import 'export_service.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(appDatabaseProvider));
});

PdfStrings pdfStringsOf(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final months = [
    for (var m = 1; m <= 12; m++)
      DateFormat.MMMM(locale).format(DateTime(2024, m)),
  ];
  return PdfStrings(
    title: l10n.pdfMonthHeader,
    allTimeHeading: l10n.exportPdfAllTime,
    statsHeading: l10n.pdfStatsHeading,
    statsTotal: l10n.pdfStatsTotal,
    statsNone: l10n.pdfStatsNone,
    statsGreen: l10n.pdfStatsGreen,
    statsYellow: l10n.pdfStatsYellow,
    statsRed: l10n.pdfStatsRed,
    entriesHeading: l10n.pdfEntriesHeading,
    triggersLabel: l10n.triggersLabel,
    medicationsLabel: l10n.medicationsLabel,
    footer: l10n.pdfFooter,
    monthNames: months,
  );
}
