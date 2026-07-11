import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/emoji_picker_dialog.dart';
import '../../model/category_model.dart';
import '../../provider/category_provider.dart';

/// Dedicated screen for managing custom categories.
class CategoryManageScreen extends ConsumerStatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  ConsumerState<CategoryManageScreen> createState() =>
      _CategoryManageScreenState();
}

class _CategoryManageScreenState extends ConsumerState<CategoryManageScreen> {
  @override
  void initState() {
    super.initState();
    // Force a fresh load when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryNotifierProvider.notifier).reload();
    });
  }

  Future<void> _showAddEditDialog({CategoryModel? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.category ?? '');
    String selectedEmoji = existing?.emoji ?? '📦';
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          final colorScheme = Theme.of(ctx).colorScheme;
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              existing == null ? 'New Category' : 'Edit Category',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji Selector
                  GestureDetector(
                    onTap: () async {
                      final emoji = await EmojiPickerDialog.show(ctx);
                      if (emoji != null)
                        setLocalState(() => selectedEmoji = emoji);
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2F3F)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00BCD4).withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            selectedEmoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00BCD4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Tap emoji to change',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Gap(16),
                  // Name Field
                  TextFormField(
                    controller: nameCtrl,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      labelStyle: GoogleFonts.outfit(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Name is required';
                      if (v.trim().length > 50) return 'Max 50 characters';
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.outfit()),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final notifier = ref.read(categoryNotifierProvider.notifier);

                  bool success;

                  if (existing == null) {
                    success = await notifier.createCategory(
                      name: nameCtrl.text.trim(),
                      emoji: selectedEmoji,
                    );
                  } else {
                    success = await notifier.updateCategory(
                      existing.copyWith(
                        category: nameCtrl.text.trim(),
                        emoji: selectedEmoji,
                      ),
                    );
                  }

                  if (!mounted) return;

                  if (success) {
                    Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'A category with that name already exists.',
                          style: GoogleFonts.outfit(),
                        ),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                ),
                child: Text(
                  existing == null ? 'Create' : 'Save',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
    // nameCtrl.dispose();
  }

  Future<void> _handleDelete(CategoryModel category) async {
    final notifier = ref.read(categoryNotifierProvider.notifier);
    final result = await notifier.deleteCategory(category);

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${category.emoji} ${category.category} deleted',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result == null) {
      // Has linked expenses — show migration dialog
      final categories = ref.read(categoryNotifierProvider).value ?? [];
      final others = categories.where((c) => c.id != category.id).toList();

      if (!mounted) return;
      if (others.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot delete — no other categories to migrate expenses to.',
              style: GoogleFonts.outfit(),
            ),
          ),
        );
        return;
      }

      CategoryModel? target = others.first;
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Migrate Expenses',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This category has linked expenses. Select a category to move them to before deleting.',
                    style: GoogleFonts.outfit(fontSize: 14),
                  ),
                  const Gap(16),
                  DropdownButtonFormField<CategoryModel>(
                    value: target,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Move expenses to',
                      labelStyle: GoogleFonts.outfit(),
                    ),
                    items: others
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.emoji} ${c.category}',
                              style: GoogleFonts.outfit(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => target = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.outfit()),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (target != null) {
                      await notifier.migrateThenDelete(category, target!.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Expenses migrated & category deleted.',
                              style: GoogleFonts.outfit(),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Migrate & Delete',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncCats = ref.watch(categoryNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Categories',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: asyncCats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cats) {
          if (cats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📂', style: const TextStyle(fontSize: 56)),
                  const Gap(16),
                  Text(
                    'No categories yet',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Gap(8),
                  FilledButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add),
                    label: Text('Add Category', style: GoogleFonts.outfit()),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                    ),
                  ),
                ],
              ),
            );
          }

          final defaults = cats.where((c) => c.isDefault).toList();
          final custom = cats.where((c) => !c.isDefault).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (defaults.isNotEmpty) ...[
                _sectionHeader('Default Categories', colorScheme),
                const Gap(8),
                ...defaults.asMap().entries.map(
                  (e) => _CategoryTile(
                    category: e.value,
                    index: e.key,
                    onEdit: null, // Default categories can't be edited
                    onDelete: null, // Default categories can't be deleted
                    isDark: isDark,
                  ),
                ),
              ],
              if (custom.isNotEmpty) ...[
                const Gap(20),
                _sectionHeader('Custom Categories', colorScheme),
                const Gap(8),
                ...custom.asMap().entries.map(
                  (e) => _CategoryTile(
                    category: e.value,
                    index: e.key,
                    onEdit: () => _showAddEditDialog(existing: e.value),
                    onDelete: () => _handleDelete(e.value),
                    isDark: isDark,
                  ),
                ),
              ],
              if (custom.isEmpty && defaults.isNotEmpty) ...[
                const Gap(24),
                Center(
                  child: FilledButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add),
                    label: Text(
                      'Add Custom Category',
                      style: GoogleFonts.outfit(),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                    ),
                  ),
                ),
              ],
              const Gap(80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF00BCD4),
        label: Icon(Icons.add, color: Colors.black, size: 20),
      ),
    );
  }

  Widget _sectionHeader(String label, ColorScheme cs) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF00BCD4),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDark;

  const _CategoryTile({
    required this.category,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252A3A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? null
                : Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            title: Text(
              category.category,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            subtitle: category.isDefault
                ? Text(
                    'Default',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  )
                : null,
            trailing: onEdit == null
                ? Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        onPressed: onEdit,
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: onDelete,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: index * 40),
          duration: 300.ms,
        )
        .slideX(begin: 0.05, end: 0);
  }
}
