import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/category_icons.dart';
import '../../../app/theme/tag_palette.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/domain/category.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../widgets/color_swatch_picker.dart';
import '../../../widgets/confirm_dialog.dart';
import 'tag_management_screen.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageCategories),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add, size: 22),
            tooltip: l10n.addCategory,
            onPressed: () => showCategoryEditor(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.emptyCategoryList, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
            itemBuilder: (ctx, i) => _CategoryTile(category: categories[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.loadFailed(e.toString()))),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tagsAsync = ref.watch(tagsByCategoryProvider(category.id));
    final count = tagsAsync.maybeWhen(data: (t) => t.length, orElse: () => 0);

    return ListTile(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => TagManagementScreen(category: category),
        ),
      ),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: category.displayColor.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(iconForKey(category.icon), size: 20, color: category.displayColor),
      ),
      title: Text(category.name),
      subtitle: Text(l10n.categoryTagCount(count)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(36),
            onPressed: () => showCategoryEditor(context, ref, existing: category),
            child: Icon(Icons.edit_outlined, size: 22, color: scheme.primary),
          ),
          const SizedBox(width: 4),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(36),
            onPressed: () => _delete(context, ref),
            child: Icon(Icons.delete_outline_rounded, size: 22, color: scheme.error),
          ),
          const SizedBox(width: 4),
          const Icon(CupertinoIcons.chevron_right, size: 16),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteCategoryTitle,
      message: l10n.deleteCategoryBody,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(categoriesDaoProvider).deleteById(category.id);
  }
}

/// Bottom-sheet editor used for both creating and editing a category.
Future<void> showCategoryEditor(
  BuildContext context,
  WidgetRef ref, {
  Category? existing,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: existing?.name ?? '');
  var iconKey = existing?.icon ?? categoryIconKeys.first;
  String? colorHex = existing?.color;

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 4,
              bottom: MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom +
                  16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? l10n.addCategoryTitle : l10n.editCategoryTitle,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: existing == null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.categoryNameHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.chooseIcon, style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in categoryIconKeys)
                        _IconChoice(
                          icon: iconForKey(key),
                          selected: key == iconKey,
                          onTap: () => setState(() => iconKey = key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.chooseColor, style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ColorSwatchPicker(
                    selected: colorHex,
                    onChanged: (v) => setState(() => colorHex = v),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (saved != true) return;
  final name = controller.text.trim();
  if (name.isEmpty) return;

  final dao = ref.read(categoriesDaoProvider);
  if (existing == null) {
    final sortOrder = await dao.nextSortOrder();
    await dao.create(name: name, icon: iconKey, color: colorHex, sortOrder: sortOrder);
  } else {
    await dao.updateCategory(existing.id, name: name, icon: iconKey, color: colorHex);
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.icon, required this.selected, required this.onTap});

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

