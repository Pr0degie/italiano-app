import 'package:flutter/material.dart';

// ── Drag-Daten ────────────────────────────────────────────────────────────────

sealed class _DragData {
  String get word;
}

class _PoolDrag extends _DragData {
  _PoolDrag(this.word);
  @override
  final String word;
}

class _SlotDrag extends _DragData {
  _SlotDrag(this.word, this.slotIndex);
  @override
  final String word;
  final int slotIndex;
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Satz-Bau-Widget: deutscher Satz oben, darunter leere Slots,
/// darunter die italienischen Wörter in zufälliger Reihenfolge.
///
/// - [germanSentence]: anzuzeigender deutscher Satz
/// - [italianWords]: korrekte Reihenfolge der italienischen Wörter
/// - [onComplete]: Callback wenn Nutzer nach Ergebnis auf "Weiter →" tippt
class SentenceBuilderWidget extends StatefulWidget {
  const SentenceBuilderWidget({
    super.key,
    required this.germanSentence,
    required this.italianWords,
    required this.onComplete,
  });

  final String germanSentence;
  final List<String> italianWords;

  /// Wird aufgerufen wenn der Nutzer nach dem Ergebnis auf "Weiter →" tippt.
  final void Function(bool correct) onComplete;

  @override
  State<SentenceBuilderWidget> createState() => _SentenceBuilderWidgetState();
}

class _SentenceBuilderWidgetState extends State<SentenceBuilderWidget> {
  late List<String> _pool;
  late List<String?> _slots;
  bool _submitted = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _pool = widget.italianWords.toList()..shuffle();
    _slots = List.filled(widget.italianWords.length, null);
  }

  // ── Tap-Logik ────────────────────────────────────────────────────────────

  void _tapPool(String word) {
    if (_submitted) return;
    final firstEmpty = _slots.indexWhere((s) => s == null);
    if (firstEmpty == -1) return;
    setState(() {
      _pool.remove(word);
      _slots[firstEmpty] = word;
    });
  }

  void _tapSlot(int index) {
    if (_submitted) return;
    final word = _slots[index];
    if (word == null) return;
    setState(() {
      _slots[index] = null;
      _pool.add(word);
    });
  }

  // ── Drop-Logik ───────────────────────────────────────────────────────────

  void _dropOnSlot(int slotIndex, _DragData data) {
    if (_submitted) return;
    final incoming = data.word;
    final existing = _slots[slotIndex];

    setState(() {
      if (data is _PoolDrag) {
        _pool.remove(incoming);
        if (existing != null) _pool.add(existing);
        _slots[slotIndex] = incoming;
      } else if (data is _SlotDrag) {
        if (data.slotIndex == slotIndex) return;
        _slots[data.slotIndex] = existing; // swap
        _slots[slotIndex] = incoming;
      }
    });
  }

  void _dropOnPool(_DragData data) {
    if (_submitted || data is! _SlotDrag) return;
    setState(() {
      _slots[data.slotIndex] = null;
      _pool.add(data.word);
    });
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  void _submit() {
    if (_submitted || _slots.any((s) => s == null)) return;
    final correct = _slots
        .asMap()
        .entries
        .every((e) => e.value == widget.italianWords[e.key]);
    setState(() {
      _submitted = true;
      _isCorrect = correct;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allFilled = _slots.every((s) => s != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 1),
        // Deutscher Satz — oberer Mittelbereich
        Text(
          widget.germanSentence,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const Spacer(flex: 3),
        // Slots (Drop-Zonen)
        _SlotsArea(
          slots: _slots,
          correctWords: widget.italianWords,
          submitted: _submitted,
          onTap: _tapSlot,
          onDrop: _dropOnSlot,
        ),
        const SizedBox(height: 20),
        Divider(color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 16),
        // Wort-Pool mit Drop-Zone (für Slot→Pool zurückziehen)
        DragTarget<_DragData>(
          onAccept: _dropOnPool,
          builder: (context, candidates, _) => _WordPool(
            words: _pool,
            disabled: _submitted,
            highlighted: candidates.isNotEmpty,
            onTap: _tapPool,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _submitted
              ? () => widget.onComplete(_isCorrect)
              : (allFilled ? _submit : null),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: _submitted
                ? (_isCorrect ? Colors.green[600] : Colors.red[600])
                : null,
          ),
          child: Text(_submitted
              ? (_isCorrect ? '✓ Richtig – Weiter →' : '✗ Falsch – Weiter →')
              : 'Prüfen'),
        ),
      ],
    );
  }
}

// ── Drag-Feedback (schwebendes Chip) ─────────────────────────────────────────

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.word});
  final String word;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          word,
          style: TextStyle(
            color: cs.onPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Slots ─────────────────────────────────────────────────────────────────────

class _SlotsArea extends StatelessWidget {
  const _SlotsArea({
    required this.slots,
    required this.correctWords,
    required this.submitted,
    required this.onTap,
    required this.onDrop,
  });

  final List<String?> slots;
  final List<String> correctWords;
  final bool submitted;
  final void Function(int index) onTap;
  final void Function(int slotIndex, _DragData data) onDrop;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < slots.length; i++)
          _SlotChip(
            word: slots[i],
            correctWord: correctWords[i],
            slotIndex: i,
            submitted: submitted,
            onTap: () => onTap(i),
            onDrop: (data) => onDrop(i, data),
          ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.word,
    required this.correctWord,
    required this.slotIndex,
    required this.submitted,
    required this.onTap,
    required this.onDrop,
  });

  final String? word;
  final String correctWord;
  final int slotIndex;
  final bool submitted;
  final VoidCallback onTap;
  final void Function(_DragData data) onDrop;

  Widget _buildChip(BuildContext context, {bool dragging = false}) {
    final cs = Theme.of(context).colorScheme;
    final isEmpty = word == null;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isEmpty) {
      bgColor = Colors.transparent;
      borderColor = cs.outlineVariant;
      textColor = Colors.transparent;
    } else if (submitted) {
      final ok = word == correctWord;
      bgColor = ok ? Colors.green[600]! : Colors.red[600]!;
      borderColor = bgColor;
      textColor = Colors.white;
    } else if (dragging) {
      bgColor = cs.secondaryContainer.withOpacity(0.4);
      borderColor = cs.secondary.withOpacity(0.4);
      textColor = Colors.transparent;
    } else {
      bgColor = cs.secondaryContainer;
      borderColor = cs.secondary;
      textColor = cs.onSecondaryContainer;
    }

    return GestureDetector(
      onTap: !isEmpty && !submitted ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          isEmpty ? correctWord : word!,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget chip = _buildChip(context);

    // Gefüllte Slots sind ziehbar (außer nach Submit)
    if (word != null && !submitted) {
      chip = Draggable<_DragData>(
        data: _SlotDrag(word!, slotIndex),
        feedback: _DragFeedback(word: word!),
        childWhenDragging: _buildChip(context, dragging: true),
        child: chip,
      );
    }

    // Jeder Slot ist Drop-Zone
    return DragTarget<_DragData>(
      onAccept: onDrop,
      builder: (context, candidates, _) {
        if (candidates.isNotEmpty && !submitted) {
          // Hover-Highlight
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: chip,
          );
        }
        return chip;
      },
    );
  }
}

// ── Word Pool ─────────────────────────────────────────────────────────────────

class _WordPool extends StatelessWidget {
  const _WordPool({
    required this.words,
    required this.onTap,
    this.disabled = false,
    this.highlighted = false,
  });

  final List<String> words;
  final void Function(String word) onTap;
  final bool disabled;
  final bool highlighted; // true wenn ein Slot-Chip drüber gezogen wird

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: highlighted
            ? cs.primaryContainer.withOpacity(0.4)
            : Colors.transparent,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final word in words)
            Draggable<_DragData>(
              data: _PoolDrag(word),
              feedback: _DragFeedback(word: word),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _poolChip(context, cs, word, disabled: true),
              ),
              child: _poolChip(context, cs, word, disabled: disabled),
            ),
        ],
      ),
    );
  }

  Widget _poolChip(BuildContext context, ColorScheme cs, String word,
      {required bool disabled}) {
    return GestureDetector(
      onTap: disabled ? null : () => onTap(word),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: disabled ? cs.surfaceContainerHighest : cs.primaryContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          word,
          style: TextStyle(
            color: disabled
                ? cs.onSurface.withOpacity(0.38)
                : cs.onPrimaryContainer,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
