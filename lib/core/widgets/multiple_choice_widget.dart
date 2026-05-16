import 'package:flutter/material.dart';

/// 2×2-Grid mit farbigen Antwort-Buttons für Multiple-Choice-Übungen.
///
/// - [options]: genau 4 Antwortmöglichkeiten
/// - [correct]: die richtige Antwort (wird grün wenn [selected] gesetzt)
/// - [selected]: aktuell gewählte Antwort (null = noch keine Auswahl)
/// - [onSelect]: Callback mit der gewählten Antwort; wird nach Auswahl gesperrt
/// - [colors]: optionale Buttonfarben (Standard: blau, pink, gelb, lila)
class MultipleChoiceWidget extends StatelessWidget {
  const MultipleChoiceWidget({
    super.key,
    required this.options,
    required this.correct,
    required this.onSelect,
    this.selected,
    this.colors = _defaultColors,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.childAspectRatio = 2.2,
  }) : assert(options.length == 4, 'MultipleChoiceWidget benötigt genau 4 Optionen');

  final List<String> options;
  final String correct;
  final String? selected;
  final ValueChanged<String> onSelect;
  final List<Color> colors;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  static const _defaultColors = [
    Color(0xFF1565C0), // blau
    Color(0xFFC2185B), // pink
    Color(0xFFF9A825), // gelb
    Color(0xFF6A1B9A), // lila
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
      children: [
        for (var i = 0; i < options.length; i++)
          _ChoiceButton(
            label: options[i],
            color: colors[i],
            selected: selected,
            correct: correct,
            onTap: selected == null ? () => onSelect(options[i]) : null,
          ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.correct,
    required this.onTap,
  });

  final String label;
  final Color color;
  final String? selected;
  final String correct;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = (selected != null && label == correct) ? Colors.green : color;

    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        disabledBackgroundColor: bg,
        disabledForegroundColor: Colors.white,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
