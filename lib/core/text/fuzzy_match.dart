/// Vergleich von User-Eingabe gegen erwartetes Zielwort, mit Toleranz für
/// Diakritika und Tippfehler.
///
/// - Diakritika werden normalisiert (`sì` == `si`, `caffè` == `caffe`).
/// - Whitespace, Groß-/Kleinschreibung und gängige Interpunktion ignoriert.
/// - Levenshtein-Distanz ≤ 1 (für Wörter ≤ 5 Zeichen) bzw. ≤ 2 (länger)
///   gilt als "fast richtig".
library;

enum MatchResult { exact, almost, wrong }

MatchResult fuzzyMatch(String input, String expected) {
  final a = _normalize(input);
  final b = _normalize(expected);
  if (a.isEmpty) return MatchResult.wrong;
  if (a == b) return MatchResult.exact;
  final tolerance = b.length <= 5 ? 1 : 2;
  final dist = _levenshtein(a, b, cap: tolerance + 1);
  return dist <= tolerance ? MatchResult.almost : MatchResult.wrong;
}

String _normalize(String s) {
  final lower = s.toLowerCase().trim();
  final buf = StringBuffer();
  for (final ch in lower.runes) {
    final mapped = _diacritics[ch] ?? ch;
    // Interpunktion entfernen (lassen Buchstaben, Ziffern, ASCII-Space stehen)
    if (mapped == 0x20 ||
        (mapped >= 0x30 && mapped <= 0x39) ||
        (mapped >= 0x61 && mapped <= 0x7A)) {
      buf.writeCharCode(mapped);
    }
  }
  // mehrfache Whitespaces zusammenfassen
  return buf.toString().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' ');
}

const _diacritics = <int, int>{
  0xE0: 0x61, 0xE1: 0x61, 0xE2: 0x61, 0xE3: 0x61, 0xE4: 0x61, 0xE5: 0x61, // à á â ã ä å
  0xE8: 0x65, 0xE9: 0x65, 0xEA: 0x65, 0xEB: 0x65, // è é ê ë
  0xEC: 0x69, 0xED: 0x69, 0xEE: 0x69, 0xEF: 0x69, // ì í î ï
  0xF2: 0x6F, 0xF3: 0x6F, 0xF4: 0x6F, 0xF5: 0x6F, 0xF6: 0x6F, // ò ó ô õ ö
  0xF9: 0x75, 0xFA: 0x75, 0xFB: 0x75, 0xFC: 0x75, // ù ú û ü
  0xFD: 0x79, 0xFF: 0x79, // ý ÿ
  0xE7: 0x63, // ç
  0xF1: 0x6E, // ñ
  0xDF: 0x73, // ß → s (approximativ; Tests dürften wenig betroffen sein)
};

/// Levenshtein-Distanz mit Early-Exit wenn [cap] erreicht wird.
int _levenshtein(String a, String b, {required int cap}) {
  if ((a.length - b.length).abs() >= cap) return cap;
  final m = a.length;
  final n = b.length;
  var prev = List<int>.generate(n + 1, (i) => i);
  var curr = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    var rowMin = curr[0];
    for (var j = 1; j <= n; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final del = prev[j] + 1;
      final ins = curr[j - 1] + 1;
      final sub = prev[j - 1] + cost;
      var v = del;
      if (ins < v) v = ins;
      if (sub < v) v = sub;
      curr[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin >= cap) return cap;
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[n];
}
