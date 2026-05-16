import 'package:flutter/material.dart';

// ── Controller ────────────────────────────────────────────────────────────────

class FlashCardController {
  _FlashCardState? _state;

  void _attach(_FlashCardState s) => _state = s;
  void _detach() => _state = null;

  /// Ob die Karte gerade die Rückseite zeigt.
  bool get isFlipped => _state?._isFlipped ?? false;

  /// Flip zur Rückseite (ignoriert wenn bereits geflippt).
  void flip() => _state?._flip();

  /// Sofort auf Vorderseite zurücksetzen (keine Animation).
  void reset() => _state?._reset();

  void dispose() => _detach();
}

// ── FlashCard ─────────────────────────────────────────────────────────────────

class FlashCard extends StatefulWidget {
  const FlashCard({
    super.key,
    required this.front,
    required this.back,
    this.controller,
    this.color,
    this.minHeight = 220,
    this.padding =
        const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
    this.onTap,
    this.onFlipMidpoint,
    this.onFlipComplete,
    this.flipDuration = const Duration(milliseconds: 450),
  });

  final Widget front;
  final Widget back;
  final FlashCardController? controller;

  /// Überschreibt die Card-Farbe (z. B. grün/rot bei Übungen).
  final Color? color;

  final double minHeight;
  final EdgeInsets padding;

  /// Wird beim Antippen aufgerufen — Parent entscheidet was passiert.
  final VoidCallback? onTap;

  /// Wird am Mittelpunkt des Flips ausgelöst (Karte steht auf Kante).
  /// Ideal um z. B. answerFlashcard() aufzurufen oder die Farbe zu resetten.
  final VoidCallback? onFlipMidpoint;

  /// Wird aufgerufen wenn die Flip-Animation abgeschlossen ist.
  final VoidCallback? onFlipComplete;

  final Duration flipDuration;

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  bool _isFlipped = false;
  bool _midpointFired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: widget.flipDuration, vsync: this);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(FlashCard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._detach();
      widget.controller?._attach(this);
    }
    _ctrl.duration = widget.flipDuration;
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Animation callbacks ────────────────────────────────────────────────────

  void _onTick() {
    if (!_midpointFired && _ctrl.value >= 0.5) {
      _midpointFired = true;
      setState(() => _isFlipped = true);
      widget.onFlipMidpoint?.call();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Controller NICHT resetten — bei angle=π bleibt die Rückseite korrekt
      // orientiert (äußere rotateY(π) + innere Gegenrotation rotateY(π) = 2π = normal).
      _midpointFired = false;
      widget.onFlipComplete?.call();
    }
  }

  // ── Controller interface ───────────────────────────────────────────────────

  void _flip() {
    if (_isFlipped) return;
    _midpointFired = false;
    _ctrl.forward();
  }

  void _reset() {
    _ctrl.reset();
    _midpointFired = false;
    if (_isFlipped) setState(() => _isFlipped = false);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final angle = _anim.value * 3.14159265;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Card(
              elevation: 4,
              color: widget.color,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: widget.minHeight,
                    minWidth: double.infinity),
                child: Padding(
                  padding: widget.padding,
                  child: Center(
                    child: _isFlipped
                        ? Transform(
                            alignment: Alignment.center,
                            transform:
                                Matrix4.identity()..rotateY(3.14159265),
                            child: widget.back,
                          )
                        : widget.front,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
