import 'dart:convert';

import 'package:drift/drift.dart';

import '../constants.dart';
import '../content/content_loader.dart';
import '../content/models.dart';
import '../database/database.dart';

/// Seeded Content aus den JSON-Assets in die Drift-DB.
///
/// Strategie: bei jedem Bump von `manifest.contentVersion` wird Content
/// neu geschrieben (User-Progress bleibt erhalten — andere Tabellen werden
/// nicht angefasst).
class ContentSeeder {
  ContentSeeder(this.db, {ContentLoader? loader})
      : _loader = loader ?? ContentLoader();

  final AppDatabase db;
  final ContentLoader _loader;

  static const _contentVersionKey = 'content_version';

  Future<void> seedIfNeeded() async {
    final loaded = await _loader.loadAll();
    final assetVersion = loaded.manifest.contentVersion.toString();
    final dbVersion = await _readDbVersion();
    if (dbVersion == assetVersion) return;

    await db.transaction(() async {
      await _clearContent();
      await _writeManifest(loaded.manifest);
      for (final lesson in loaded.lessons) {
        await _writeLesson(lesson);
      }
      await _writeDbVersion(assetVersion);
    });
  }

  // ── Schreiben ────────────────────────────────────────────────────────────

  Future<void> _writeManifest(ContentManifest m) async {
    for (final c in m.chapters) {
      await db.into(db.chapters).insertOnConflictUpdate(
            ChaptersCompanion.insert(id: c.id, sortOrder: c.sortOrder),
          );
      await db.into(db.chapterTranslations).insertOnConflictUpdate(
            ChapterTranslationsCompanion.insert(
              chapterId: c.id,
              lang: AppConstants.activeLang,
              title: c.title,
            ),
          );
    }
  }

  Future<void> _writeLesson(ContentLesson lesson) async {
    await db.into(db.lessons).insertOnConflictUpdate(
          LessonsCompanion.insert(
            id: lesson.id,
            chapterId: lesson.chapterId,
            sortOrder: lesson.sortOrder,
          ),
        );
    await db.into(db.lessonTranslations).insertOnConflictUpdate(
          LessonTranslationsCompanion.insert(
            lessonId: lesson.id,
            lang: AppConstants.activeLang,
            title: lesson.title,
          ),
        );

    for (var i = 0; i < lesson.steps.length; i++) {
      final step = lesson.steps[i];
      switch (step) {
        case VocabContentStep():
          await _writeVocabStep(lesson.id, i + 1, step);
        case SentenceBuilderContentStep():
          await _writeSentenceBuilderStep(lesson.id, i + 1, step);
      }
    }
  }

  Future<void> _writeVocabStep(
      String lessonId, int sortOrder, VocabContentStep step) async {
    await db.into(db.items).insertOnConflictUpdate(
          ItemsCompanion.insert(id: step.itemId, type: 'vocab'),
        );
    await db.into(db.vocabItems).insertOnConflictUpdate(
          VocabItemsCompanion.insert(
            itemId: step.itemId,
            front: step.target,
            partOfSpeech: Value(step.partOfSpeech),
          ),
        );
    await db.into(db.itemTranslations).insertOnConflictUpdate(
          ItemTranslationsCompanion.insert(
            itemId: step.itemId,
            lang: AppConstants.activeLang,
            translation: step.native,
          ),
        );
    await db.into(db.lessonSteps).insertOnConflictUpdate(
          LessonStepsCompanion.insert(
            lessonId: lessonId,
            sortOrder: sortOrder,
            itemId: Value(step.itemId),
            suggestedExerciseType: const Value('mc'),
          ),
        );
  }

  Future<void> _writeSentenceBuilderStep(String lessonId, int sortOrder,
      SentenceBuilderContentStep step) async {
    // Payload = JSON-Objekt mit den Wörtern in Zielsprache (Reihenfolge=korrekt).
    final payload = jsonEncode({'words': step.targetWords});
    await db.into(db.exercises).insertOnConflictUpdate(
          ExercisesCompanion.insert(
            id: step.exerciseId,
            type: 'sentence_builder',
            payload: Value(payload),
          ),
        );
    await db.into(db.exerciseTranslations).insertOnConflictUpdate(
          ExerciseTranslationsCompanion.insert(
            exerciseId: step.exerciseId,
            lang: AppConstants.activeLang,
            prompt: Value(step.nativePrompt),
          ),
        );
    await db.into(db.lessonSteps).insertOnConflictUpdate(
          LessonStepsCompanion.insert(
            lessonId: lessonId,
            sortOrder: sortOrder,
            exerciseId: Value(step.exerciseId),
          ),
        );
  }

  // ── Aufräumen + Versionierung ────────────────────────────────────────────

  Future<void> _clearContent() async {
    // Cascade-Deletes räumen abhängige Tabellen mit auf
    await db.delete(db.lessonSteps).go();
    await db.delete(db.exerciseTranslations).go();
    await db.delete(db.exercises).go();
    await db.delete(db.lessonTranslations).go();
    await db.delete(db.lessons).go();
    await db.delete(db.chapterTranslations).go();
    await db.delete(db.chapters).go();
    await db.delete(db.itemTranslations).go();
    await db.delete(db.vocabItems).go();
    await db.delete(db.items).go();
  }

  Future<String> _readDbVersion() async {
    final row = await (db.select(db.meta)
          ..where((m) => m.key.equals(_contentVersionKey)))
        .getSingleOrNull();
    return row?.value ?? '0';
  }

  Future<void> _writeDbVersion(String version) async {
    await db.into(db.meta).insertOnConflictUpdate(
          MetaCompanion.insert(key: _contentVersionKey, value: version),
        );
  }
}
