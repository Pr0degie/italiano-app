import 'package:drift/drift.dart';

class Meta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class Items extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'vocab' | 'grammar' | 'sentence'
  TextColumn get audioRef => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class VocabItems extends Table {
  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();
  TextColumn get front => text()(); // italienisch
  TextColumn get ipa => text().nullable()();
  TextColumn get partOfSpeech => text().nullable()();
  TextColumn get gender => text().nullable()(); // 'm' | 'f'
  TextColumn get plural => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};
}

class ItemTranslations extends Table {
  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();
  TextColumn get lang => text()();
  TextColumn get translation => text()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId, lang};
}
