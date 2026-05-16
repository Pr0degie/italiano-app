import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/chapters.dart';
import 'tables/content.dart';
import 'tables/exercises.dart';
import 'tables/lessons.dart';
import 'tables/progress.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Meta,
  Items,
  VocabItems,
  ItemTranslations,
  Exercises,
  ExerciseTranslations,
  Chapters,
  ChapterTranslations,
  Lessons,
  LessonTranslations,
  LessonSteps,
  ReviewState,
  LessonProgress,
  DailyActivity,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(chapters);
            await m.createTable(chapterTranslations);
            await m.addColumn(lessons, lessons.chapterId);
          }
          if (from < 3) {
            await m.addColumn(reviewState, reviewState.lastReviewedDate);
            await m.addColumn(
                reviewState, reviewState.consecutiveCorrectDays);
            await m.addColumn(reviewState, reviewState.masteredAt);
            // dueDate nullable machen geht per migration nicht direkt —
            // bestehende Zeilen behalten ihren dueDate-Wert, neue können null haben.
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'italiano_app');
  }
}
