import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../database/database.dart';
import 'dummy_content.dart';

class ContentSeeder {
  ContentSeeder(this.db);
  final AppDatabase db;

  static const _contentVersionKey = 'content_version';
  static const _manifestPath = 'assets/content/manifest.json';

  Future<void> seedIfNeeded() async {
    final assetVersion = await _readAssetVersion();
    final dbVersion = await _readDbVersion();
    if (dbVersion == assetVersion) return;

    await db.transaction(() async {
      await _clearContent();
      await DummyContent.seed(db);
      await _writeDbVersion(assetVersion);
    });
  }

  Future<void> _clearContent() async {
    // Cascade-Deletes räumen abhängige Tabellen mit auf
    await db.delete(db.lessonSteps).go();
    await db.delete(db.lessonTranslations).go();
    await db.delete(db.lessons).go();
    await db.delete(db.chapterTranslations).go();
    await db.delete(db.chapters).go();
    await db.delete(db.itemTranslations).go();
    await db.delete(db.vocabItems).go();
    await db.delete(db.items).go();
  }

  Future<String> _readAssetVersion() async {
    try {
      final raw = await rootBundle.loadString(_manifestPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (json['content_version'] as String?) ?? '0';
    } catch (_) {
      return '0';
    }
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
