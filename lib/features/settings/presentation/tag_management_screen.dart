import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/domain/tag.dart';
import '../../../core/domain/tag_kind.dart';
import '../../../core/i18n/app_localizations.dart';

class TagManagementScreen extends ConsumerWidget {
  const TagManagementScreen({required this.kind, super.key});

  final TagKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = kind == TagKind.trigger
        ? l10n.manageTriggersTitle
        : l10n.manageMedicationsTitle;
    final tagsAsync = kind == TagKind.trigger
        ? ref.watch(triggerTagsProvider)
        : ref.watch(medicationTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add, size: 22),
            tooltip: l10n.addTag,
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: tagsAsync.when(
        data: (tags) {
          if (tags.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.emptyTagList,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final custom = tags.where((t) => t.isCustom).toList();
          final builtIn = tags.where((t) => !t.isCustom).toList();

          final children = <Widget>[];
          if (custom.isNotEmpty) {
            children
              ..add(_SectionHeader(l10n.tagGroupCustom))
              ..addAll(_intersperse(
                custom.map((t) => _TagTile(tag: t, kind: kind)),
              ));
          }
          if (builtIn.isNotEmpty) {
            children
              ..add(_SectionHeader(l10n.tagGroupBuiltIn))
              ..addAll(_intersperse(
                builtIn.map((t) => _TagTile(tag: t, kind: kind)),
              ));
          }
          children.add(const SizedBox(height: 24));
          return ListView(children: children);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.loadFailed(e.toString()))),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final name = await showCupertinoDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.addTagDialogTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: l10n.addTagHint,
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.addTag),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    // User-created tags always belong in the "Eigene" group.
    await ref.read(tagsDaoProvider).insertIfMissing(
          name: name,
          kind: kind.value,
          isCustom: true,
        );
  }
}

/// Inserts a thin divider between each [tiles] item without trailing one
/// after the last row. Matches iOS' grouped-list look between section header
/// and the rows below.
Iterable<Widget> _intersperse(Iterable<Widget> tiles) sync* {
  var first = true;
  for (final t in tiles) {
    if (!first) yield const Divider(height: 1, indent: 16);
    first = false;
    yield t;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _TagTile extends ConsumerWidget {
  const _TagTile({required this.tag, required this.kind});

  final Tag tag;
  final TagKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(tag.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(36),
            onPressed: () => _rename(context, ref),
            child: Icon(
              CupertinoIcons.pencil_circle_fill,
              size: 26,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(36),
            onPressed: () => _delete(context, ref),
            child: Icon(
              CupertinoIcons.minus_circle_fill,
              size: 26,
              color: scheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.deleteTagTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.deleteTagBody),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(tagsDaoProvider).deleteById(tag.id);
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: tag.name);
    final l10n = AppLocalizations.of(context);
    final name = await showCupertinoDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.renameTagTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: l10n.addTagHint,
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == tag.name) return;
    await ref.read(tagsDaoProvider).rename(tag.id, name);
  }
}
