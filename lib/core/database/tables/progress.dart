import 'package:drift/drift.dart';
import 'content.dart';
import 'lessons.dart';

@TableIndex(name: 'review_state_due', columns: {#dueDate})
class ReviewState extends Table {
  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();
  RealColumn get easiness => real().withDefault(const Constant(2.5))();
  IntColumn get interval => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get lastReviewed => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};
}

class LessonProgress extends Table {
  TextColumn get lessonId =>
      text().references(Lessons, #id, onDelete: KeyAction.cascade)();
  TextColumn get status =>
      text()(); // 'not_started' | 'in_progress' | 'completed'
  IntColumn get score => integer().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {lessonId};
}

class DailyActivity extends Table {
  TextColumn get date => text()(); // 'YYYY-MM-DD'
  IntColumn get itemsDone => integer().withDefault(const Constant(0))();
  IntColumn get lessonsDone => integer().withDefault(const Constant(0))();
  BoolColumn get goalMet => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {date};
}
