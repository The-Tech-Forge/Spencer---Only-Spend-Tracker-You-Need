import 'package:drift/drift.dart';

/// Drift table for expense categories (e.g., Food, Travel, Bills).
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text().withLength(min: 1, max: 50).unique()();
  TextColumn get emoji => text().withLength(min: 1, max: 8)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

