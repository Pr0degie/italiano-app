import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../text/fuzzy_match.dart';

/// Freitext-Übung: User sieht [nativePrompt] und tippt das Zielsprache-Wort.
///
/// Auswertung über [fuzzyMatch]:
/// - exact / almost (Tippfehler-Toleranz) → grün/gelb, `onComplete(true)`
/// - wrong → rot, korrektes Wort wird angezeigt, `onComplete(false)`
///
/// Long-Press auf das angezeigte Ergebnis (nach Submit) liest es vor.
class TypingWidget extends ConsumerStatefulWidget {
  const TypingWidget({
    super.key,
    required this.nativePrompt,
    required this.targetAnswer,
    required this.onComplete,
  });

  final String nativePrompt;
  final String targetAnswer;
  final void Function(bool correct) onComplete;

  @override
  ConsumerState<TypingWidget> createState() => _TypingWidgetState();
}

class _TypingWidgetState extends ConsumerState<TypingWidget> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  MatchResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_result != null) return;
    final input = _ctrl.text;
    if (input.trim().isEmpty) return;
    setState(() => _result = fuzzyMatch(input, widget.targetAnswer));
    _focus.unfocus();
  }

  void _next() {
    final correct =
        _result == MatchResult.exact || _result == MatchResult.almost;
    widget.onComplete(correct);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final submitted = _result != null;

    Color? borderColor;
    String? hint;
    if (submitted) {
      switch (_result!) {
        case MatchResult.exact:
          borderColor = Colors.green;
          break;
        case MatchResult.almost:
          borderColor = Colors.amber.shade700;
          hint = 'Fast richtig: ${widget.targetAnswer}';
          break;
        case MatchResult.wrong:
          borderColor = Colors.red;
          hint = 'Richtig: ${widget.targetAnswer}';
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text('Übersetze:',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          widget.nativePrompt,
          style: tt.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          enabled: !submitted,
          textAlign: TextAlign.center,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          style: tt.headlineSmall,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            enabledBorder: borderColor != null
                ? OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor, width: 2))
                : null,
            disabledBorder: borderColor != null
                ? OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor, width: 2))
                : null,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onLongPress: () =>
                ref.read(audioServiceProvider).speak(widget.targetAnswer),
            child: Text(hint,
                style: tt.bodyMedium?.copyWith(color: borderColor),
                textAlign: TextAlign.center),
          ),
        ],
        const Spacer(),
        FilledButton(
          onPressed: submitted ? _next : _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor:
                submitted && borderColor != null ? borderColor : null,
          ),
          child: Text(submitted ? 'Weiter →' : 'Prüfen'),
        ),
      ],
    );
  }
}
