import 'package:drift/drift.dart';
import 'content.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'mc' | 'pair' | 'typing' | 'listening' | ...
  TextColumn get itemId => text()
      .nullable()
      .references(Items, #id, onDelete: KeyAction.setNull)();
  TextColumn get payload => text().nullable()(); // JSON, typspezifisch

  @override
  Set<Column> get primaryKey => {id};
}

class ExerciseTranslations extends Table {
  TextColumn get exerciseId =>
      text().references(Exercises, #id, onDelete: KeyAction.cascade)();
  TextColumn get lang => text()();
  TextColumn get prompt => text().nullable()();
  TextColumn get explanation => text().nullable()();

  @override
  Set<Column> get primaryKey => {exerciseId, lang};
}
