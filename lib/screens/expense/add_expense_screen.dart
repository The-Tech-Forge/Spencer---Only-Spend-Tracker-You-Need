import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../model/category_model.dart';
import '../../model/expense_model.dart';
import '../../provider/category_provider.dart';
import '../../provider/expense_provider.dart';

/// Add or Edit expense screen.
/// When [editId] is provided, the form is pre-filled for editing.
class AddExpenseScreen extends ConsumerStatefulWidget {
  final int? editId;
  const AddExpenseScreen({super.key, this.editId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  CategoryModel? _selectedCategory;
  DateTime _date = DateTime.now();
  bool _isIncome = false;
  bool _isSaving = false;
  bool _isLoaded = false;

  ExpenseModel? _existingExpense;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded && widget.editId != null) {
      _loadExisting();
      _isLoaded = true;
    }
  }

  Future<void> _loadExisting() async {
    final all = await ref.read(expenseRepositoryProvider).getAllExpenses();
    final found = all.where((e) => e.id == widget.editId).firstOrNull;
    if (found != null && mounted) {
      setState(() {
        _existingExpense = found;
        _amountCtrl.text = found.amount.toStringAsFixed(2);
        _noteCtrl.text = found.note ?? '';
        _date = found.date;
        _isIncome = found.isIncome;
        _selectedCategory = found.category;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountCtrl.text.trim());
      final repo = ref.read(expenseRepositoryProvider);

      if (_existingExpense != null) {
        await repo.updateExpense(_existingExpense!.copyWith(
          amount: amount,
          category: _selectedCategory,
          date: _date,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          isIncome: _isIncome,
        ));
      } else {
        await repo.addExpense(
          amount: amount,
          categoryId: _selectedCategory!.id,
          date: _date,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          isIncome: _isIncome,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B6B)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(expenseRepositoryProvider).deleteExpense(widget.editId!);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.editId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Expense' : 'Add Expense',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Income toggle ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF252A3A)
                      : const Color(0xFFEFF7F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _typeTab('Expense', !_isIncome, const Color(0xFFFF6B6B),
                        () => setState(() => _isIncome = false)),
                    _typeTab('Income', _isIncome, const Color(0xFF10B981),
                        () => setState(() => _isIncome = true)),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const Gap(24),

              // ── Amount ──────────────────────────────────────────────────
              _sectionLabel('Amount'),
              const Gap(8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _isIncome
                      ? const Color(0xFF10B981)
                      : colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _isIncome
                        ? const Color(0xFF10B981)
                        : const Color(0xFF00BCD4),
                  ),
                  hintText: '0.00',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(
                    begin: -0.05,
                    end: 0,
                    delay: 100.ms,
                    duration: 400.ms,
                  ),

              const Gap(24),

              // ── Category ────────────────────────────────────────────────
              _sectionLabel('Category'),
              const Gap(8),
              categoriesAsync.when(
                data: (cats) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252A3A)
                        : const Color(0xFFEFF7F9),
                    borderRadius: BorderRadius.circular(14),
                    border: _selectedCategory != null
                        ? Border.all(
                            color: const Color(0xFF00BCD4), width: 1.5)
                        : null,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CategoryModel>(
                      value: _selectedCategory,
                      hint: Text('Select category',
                          style: GoogleFonts.outfit(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5))),
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(14),
                      items: cats.map((cat) {
                        return DropdownMenuItem<CategoryModel>(
                          value: cat,
                          child: Row(
                            children: [
                              Text(cat.emoji,
                                  style: const TextStyle(fontSize: 20)),
                              const Gap(10),
                              Text(cat.category,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Error loading categories'),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const Gap(24),

              // ── Date ────────────────────────────────────────────────────
              _sectionLabel('Date'),
              const Gap(8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252A3A)
                        : const Color(0xFFEFF7F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF00BCD4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 20, color: Color(0xFF00BCD4)),
                      const Gap(12),
                      Text(
                        DateFormat('d MMMM yyyy').format(_date),
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const Gap(24),

              // ── Note ────────────────────────────────────────────────────
              _sectionLabel('Note (optional)'),
              const Gap(8),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add a note…',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                maxLines: 2,
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const Gap(40),

              // ── Action Buttons ──────────────────────────────────────────────
              Row(
                children: [
                  if (isEditing) ...[
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _delete,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF6B6B)),
                            foregroundColor: const Color(0xFFFF6B6B),
                          ),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(16),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isIncome
                              ? const Color(0xFF10B981)
                              : const Color(0xFF00BCD4),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                isEditing ? 'Update' : 'Save',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    delay: 500.ms,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF00BCD4),
          letterSpacing: 0.5,
        ),
      );

  Widget _typeTab(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
