// Nicht mehr verwendet — review_session_notifier.dart lädt direkt.
// Datei bleibt für spätere Erweiterungen als Stub.

import '../lesson/lesson_providers.dart';
import '../../core/database/database.dart';

class ReviewItemData {
  const ReviewItemData({required this.vocab, required this.reviewState});
  final VocabStepData vocab;
  final ReviewStateData reviewState;
}
