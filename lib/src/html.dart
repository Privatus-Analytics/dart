/// Escapes text for an HTML attribute value or text node.
///
/// Escapes `&`, `<`, `>`, `"` and `'`, like Ruby's `CGI.escapeHTML`.
String escapeHtml(Object? value) {
  final text = '${value ?? ''}';
  final out = StringBuffer();
  for (final unit in text.codeUnits) {
    switch (unit) {
      case 0x26:
        out.write('&amp;');
      case 0x3C:
        out.write('&lt;');
      case 0x3E:
        out.write('&gt;');
      case 0x22:
        out.write('&quot;');
      case 0x27:
        out.write('&#39;');
      default:
        out.writeCharCode(unit);
    }
  }
  return out.toString();
}

/// Cuts [text] to at most [max] characters (Unicode code points), so an emoji
/// is never cut in half.
String cut(String text, int max) {
  if (text.length <= max) return text;
  final runes = text.runes;
  if (runes.length <= max) return text;
  return String.fromCharCodes(runes.take(max));
}
