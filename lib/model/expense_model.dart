import 'category_model.dart';

/// Pure Dart model for a spend/expense record, with its joined category.
class ExpenseModel {
  final int id;
  final double amount;
  final CategoryModel category;
  final DateTime date;
  final String? note;
  final bool isIncome;

  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.isIncome = false,
  });

  ExpenseModel copyWith({
    int? id,
    double? amount,
    CategoryModel? category,
    DateTime? date,
    String? note,
    bool? isIncome,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}
