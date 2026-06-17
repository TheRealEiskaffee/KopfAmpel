import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/i18n/app_localizations.dart';

/// iOS-style time picker: a spinning-wheel CupertinoDatePicker in
/// time mode, presented in a modal bottom sheet with Abbrechen / Fertig
/// buttons across the top. Returns the picked [TimeOfDay] or `null` if
/// the user cancels.
Future<TimeOfDay?> showCupertinoTimeSheet(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: false,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      var selected = initialTime;
      final initial = DateTime(
        2024,
        1,
        1,
        initialTime.hour,
        initialTime.minute,
      );
      return SafeArea(
        top: false,
        child: SizedBox(
          height: 280,
          child: Column(
            children: [
              Row(
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    onPressed: () => Navigator.of(ctx).pop(selected),
                    child: Text(
                      l10n.save,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: initial,
                  minuteInterval: 5,
                  onDateTimeChanged: (dt) {
                    selected = TimeOfDay(hour: dt.hour, minute: dt.minute);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
