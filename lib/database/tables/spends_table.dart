import 'package:drift/drift.dart';
import 'categories_table.dart';

/// Drift table for individual spend (expense) records.
/// [categoryId] is a foreign key referencing [Categories.id].
class Spends extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// Amount in the user's default currency (stored as double)
  RealColumn get amount => real()();
  /// Foreign key to categories
  IntColumn get categoryId =>
      integer().references(Categories, #id)();
  /// Transaction date stored as ISO-8601 string
  TextColumn get date => text()();
  /// Optional note for the expense
  TextColumn get note => text().nullable()();
  /// true = income entry, false = expense entry (future-ready)
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();
}
