import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../constants.dart';
import 'models.dart';

/// Lädt das gesamte Lerncontent-Manifest aus den Assets.
///
/// Asset-Layout:
///   `assets/content/{targetLang}/manifest.json`
///   `assets/content/{targetLang}/lessons/{lessonId}.json`
class ContentLoader {
  ContentLoader({AssetBundle? bundle, String? targetLang})
      : _bundle = bundle ?? rootBundle,
        _targetLang = targetLang ?? AppConstants.targetLang;

  final AssetBundle _bundle;
  final String _targetLang;

  String get _basePath => 'assets/content/$_targetLang';

  Future<ContentManifest> loadManifest() async {
    final raw = await _bundle.loadString('$_basePath/manifest.json');
    return ContentManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<ContentLesson> loadLesson(String relativePath) async {
    final raw = await _bundle.loadString('$_basePath/$relativePath');
    return ContentLesson.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Lädt Manifest und alle referenzierten Lessons.
  Future<LoadedContent> loadAll() async {
    final manifest = await loadManifest();
    final lessons = <ContentLesson>[];
    for (final chapter in manifest.chapters) {
      for (final file in chapter.lessonFiles) {
        lessons.add(await loadLesson(file));
      }
    }
    return LoadedContent(manifest: manifest, lessons: lessons);
  }
}

class LoadedContent {
  const LoadedContent({required this.manifest, required this.lessons});
  final ContentManifest manifest;
  final List<ContentLesson> lessons;
}
