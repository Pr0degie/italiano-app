/// Modelle für aus JSON geladenen Lerninhalt.
///
/// JSON-Layout:
///   `assets/content/{targetLang}/manifest.json`
///   `assets/content/{targetLang}/lessons/{lessonId}.json`
///
/// Ein Step ist entweder eine Vokabel (`kind: "vocab"`) oder eine Übung
/// (`kind: "sentence_builder"`, später `pair`, `typing`, ...).
library;

class ContentManifest {
  const ContentManifest({
    required this.schemaVersion,
    required this.contentVersion,
    required this.targetLang,
    required this.nativeLang,
    required this.chapters,
  });

  factory ContentManifest.fromJson(Map<String, dynamic> json) => ContentManifest(
        schemaVersion: json['schemaVersion'] as int,
        contentVersion: json['contentVersion'] as int,
        targetLang: json['targetLang'] as String,
        nativeLang: json['nativeLang'] as String,
        chapters: (json['chapters'] as List)
            .map((c) => ContentChapter.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  /// JSON-Format-Version. Bei Breaking-Changes hochzählen.
  final int schemaVersion;

  /// Inhalts-Revision. Bei jeder Content-Änderung hochzählen → triggert Re-Seed.
  final int contentVersion;

  final String targetLang;
  final String nativeLang;
  final List<ContentChapter> chapters;
}

class ContentChapter {
  const ContentChapter({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.lessonFiles,
  });

  factory ContentChapter.fromJson(Map<String, dynamic> json) => ContentChapter(
        id: json['id'] as String,
        title: json['title'] as String,
        sortOrder: json['sortOrder'] as int,
        lessonFiles: (json['lessonFiles'] as List).cast<String>(),
      );

  final String id;
  final String title;
  final int sortOrder;

  /// Relative Pfade zu Lesson-JSON-Dateien (relativ zum content-Ordner).
  final List<String> lessonFiles;
}

class ContentLesson {
  const ContentLesson({
    required this.id,
    required this.chapterId,
    required this.sortOrder,
    required this.title,
    required this.steps,
  });

  factory ContentLesson.fromJson(Map<String, dynamic> json) => ContentLesson(
        id: json['id'] as String,
        chapterId: json['chapterId'] as String,
        sortOrder: json['sortOrder'] as int,
        title: json['title'] as String,
        steps: (json['steps'] as List)
            .map((s) => ContentStep.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final String chapterId;
  final int sortOrder;
  final String title;
  final List<ContentStep> steps;
}

sealed class ContentStep {
  const ContentStep();

  factory ContentStep.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String;
    return switch (kind) {
      'vocab' => VocabContentStep.fromJson(json),
      'sentence_builder' => SentenceBuilderContentStep.fromJson(json),
      _ => throw FormatException('Unbekannter step kind: $kind'),
    };
  }
}

class VocabContentStep extends ContentStep {
  const VocabContentStep({
    required this.itemId,
    required this.target,
    required this.native,
    this.partOfSpeech,
    this.suggestedExerciseType,
  });

  factory VocabContentStep.fromJson(Map<String, dynamic> json) =>
      VocabContentStep(
        itemId: json['itemId'] as String,
        target: json['target'] as String,
        native: json['native'] as String,
        partOfSpeech: json['partOfSpeech'] as String?,
        suggestedExerciseType: json['suggested'] as String?,
      );

  final String itemId;
  final String target;
  final String native;
  final String? partOfSpeech;

  /// Optional: 'mc' (Default), 'pair', 'typing'. Steuert die Übungs-Generierung
  /// in der Exercise-Phase.
  final String? suggestedExerciseType;
}

class SentenceBuilderContentStep extends ContentStep {
  const SentenceBuilderContentStep({
    required this.exerciseId,
    required this.nativePrompt,
    required this.targetWords,
  });

  factory SentenceBuilderContentStep.fromJson(Map<String, dynamic> json) =>
      SentenceBuilderContentStep(
        exerciseId: json['exerciseId'] as String,
        nativePrompt: json['nativePrompt'] as String,
        targetWords: (json['targetWords'] as List).cast<String>(),
      );

  final String exerciseId;
  final String nativePrompt;
  final List<String> targetWords;
}
