import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';

/// Pair-Match-Übung: Vokabeln paarweise zuordnen.
///
/// Zwei Spalten: links Zielsprache (`targets`), rechts Muttersprache (`natives`).
/// `targets[i]` und `natives[i]` sind das korrekte Paar (gleiche Indizierung).
/// Das Widget shuffled jede Spalte intern.
///
/// Tap: zuerst eine Karte links, dann eine rechts (oder umgekehrt).
/// Match → beide grün und ausgegraut. Kein Match → beide kurz rot, dann zurück
/// (Fehler wird gezählt). Wenn alle Paare gematcht sind → [onComplete] mit
/// `allCorrect = (fehlerzähler == 0)`.
class PairWidget extends ConsumerStatefulWidget {
  const PairWidget({
    super.key,
    required this.targets,
    required this.natives,
    required this.onComplete,
  })  : assert(targets.length == natives.length,
            'targets und natives müssen gleich lang sein');

  final List<String> targets;
  final List<String> natives;
  final void Function(bool allCorrect) onComplete;

  @override
  ConsumerState<PairWidget> createState() => _PairWidgetState();
}

enum _Side { target, native }

class _PairWidgetState extends ConsumerState<PairWidget> {
  /// Display-Index → Original-Index (für Match-Check).
  late final List<int> _targetOrder;
  late final List<int> _nativeOrder;

  /// Pro Display-Index: gematcht?
  late final List<bool> _targetMatched;
  late final List<bool> _nativeMatched;

  /// Pro Display-Index: aktuell rot (falscher Match)?
  late List<bool> _targetWrong;
  late List<bool> _nativeWrong;

  int? _selectedTargetIdx;
  int? _selectedNativeIdx;

  int _mistakes = 0;
  bool _completed = false;

  static const _colors = [
    Color(0xFF1565C0), // blau
    Color(0xFFC2185B), // pink
    Color(0xFFF9A825), // gelb
    Color(0xFF6A1B9A), // lila
    Color(0xFF2E7D32), // grün (für Pair-Größen >4)
  ];

  @override
  void initState() {
    super.initState();
    final n = widget.targets.length;
    _targetOrder = List.generate(n, (i) => i)..shuffle();
    _nativeOrder = List.generate(n, (i) => i)..shuffle();
    // richtige Paare dürfen nicht auf gleicher Höhe stehen
    if (n >= 2) {
      var tries = 0;
      while (_hasAlignedPair() && tries < 50) {
        _nativeOrder.shuffle();
        tries++;
      }
      // Fallback: jeden Kollisionsindex mit Nachbar tauschen
      for (var i = 0; i < n; i++) {
        if (_targetOrder[i] == _nativeOrder[i]) {
          final j = (i + 1) % n;
          final tmp = _nativeOrder[i];
          _nativeOrder[i] = _nativeOrder[j];
          _nativeOrder[j] = tmp;
        }
      }
    }
    _targetMatched = List.filled(n, false);
    _nativeMatched = List.filled(n, false);
    _targetWrong = List.filled(n, false);
    _nativeWrong = List.filled(n, false);
  }

  bool _hasAlignedPair() {
    for (var i = 0; i < _targetOrder.length; i++) {
      if (_targetOrder[i] == _nativeOrder[i]) return true;
    }
    return false;
  }

  // ── Logik ──────────────────────────────────────────────────────────────────

  void _onTap(_Side side, int displayIdx) {
    if (_completed) return;
    // gematchte oder gerade rot blinkende Karten ignorieren
    final matched =
        side == _Side.target ? _targetMatched : _nativeMatched;
    final wrong = side == _Side.target ? _targetWrong : _nativeWrong;
    if (matched[displayIdx] || wrong[displayIdx]) return;

    setState(() {
      if (side == _Side.target) {
        _selectedTargetIdx = displayIdx;
      } else {
        _selectedNativeIdx = displayIdx;
      }
    });

    if (_selectedTargetIdx != null && _selectedNativeIdx != null) {
      _evaluatePair();
    }
  }

  void _evaluatePair() {
    final ti = _selectedTargetIdx!;
    final ni = _selectedNativeIdx!;
    final isMatch = _targetOrder[ti] == _nativeOrder[ni];

    if (isMatch) {
      setState(() {
        _targetMatched[ti] = true;
        _nativeMatched[ni] = true;
        _selectedTargetIdx = null;
        _selectedNativeIdx = null;
      });
      if (_targetMatched.every((m) => m)) {
        _completed = true;
        // kurze Pause für visuelles Feedback, dann weiter
        Timer(const Duration(milliseconds: 400), () {
          if (mounted) widget.onComplete(_mistakes == 0);
        });
      }
    } else {
      _mistakes++;
      setState(() {
        _targetWrong[ti] = true;
        _nativeWrong[ni] = true;
      });
      Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _targetWrong[ti] = false;
          _nativeWrong[ni] = false;
          _selectedTargetIdx = null;
          _selectedNativeIdx = null;
        });
      });
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Wörter zuordnen',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildColumn(_Side.target)),
              const SizedBox(width: 12),
              Expanded(child: _buildColumn(_Side.native)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(_Side side) {
    final n = widget.targets.length;
    final order = side == _Side.target ? _targetOrder : _nativeOrder;
    final matched = side == _Side.target ? _targetMatched : _nativeMatched;
    final wrong = side == _Side.target ? _targetWrong : _nativeWrong;
    final selected = side == _Side.target
        ? _selectedTargetIdx
        : _selectedNativeIdx;
    final source = side == _Side.target ? widget.targets : widget.natives;

    return Column(
      children: [
        for (var displayIdx = 0; displayIdx < n; displayIdx++) ...[
          if (displayIdx > 0) const SizedBox(height: 12),
          Expanded(
            child: _PairCard(
              label: source[order[displayIdx]],
              baseColor: _colors[order[displayIdx] % _colors.length],
              matched: matched[displayIdx],
              wrong: wrong[displayIdx],
              selected: selected == displayIdx,
              onTap: () => _onTap(side, displayIdx),
              onLongPress: side == _Side.target
                  ? () => ref
                      .read(audioServiceProvider)
                      .speak(source[order[displayIdx]])
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _PairCard extends StatelessWidget {
  const _PairCard({
    required this.label,
    required this.baseColor,
    required this.matched,
    required this.wrong,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final Color baseColor;
  final bool matched;
  final bool wrong;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    if (matched) {
      bg = Colors.grey.shade400;
    } else if (wrong) {
      bg = Colors.red.shade600;
    } else {
      bg = baseColor;
    }

    return GestureDetector(
      onLongPress: matched ? null : onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: Colors.white, width: 3)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: matched ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        matched ? Colors.grey.shade700 : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
