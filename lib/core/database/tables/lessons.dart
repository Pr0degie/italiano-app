import 'package:drift/drift.dart';
import 'chapters.dart';
import 'content.dart';
import 'exercises.dart';

class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get chapterId =>
      text().references(Chapters, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class LessonTranslations extends Table {
  TextColumn get lessonId =>
      text().references(Lessons, #id, onDelete: KeyAction.cascade)();
  TextColumn get lang => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {lessonId, lang};
}

@TableIndex(name: 'lesson_steps_lesson_order', columns: {#lessonId, #sortOrder})
class LessonSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lessonId =>
      text().references(Lessons, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer()();
  TextColumn get itemId => text()
      .nullable()
      .references(Items, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()
      .nullable()
      .references(Exercises, #id, onDelete: KeyAction.cascade)();
  TextColumn get suggestedExerciseType =>
      text().nullable()(); // bei item-step: welcher Übungstyp generiert werden soll

  @override
  List<String> get customConstraints => [
        'CHECK ((item_id IS NOT NULL) <> (exercise_id IS NOT NULL))',
      ];
}
