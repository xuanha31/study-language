/// Tiện ích xử lý pinyin có dấu thanh điệu — phục vụ câu hỏi "thanh điệu" (E4-2).
///
/// Quy ước thanh: 1 = ngang (ā), 2 = sắc (á), 3 = hỏi/huyền lượn (ǎ), 4 = nặng (à),
/// 0 = nhẹ/không dấu (a).
class PinyinUtil {
  PinyinUtil._();

  // Bảng nguyên âm có dấu theo thanh 1..4.
  static const Map<String, List<String>> _marks = {
    'a': ['ā', 'á', 'ǎ', 'à'],
    'e': ['ē', 'é', 'ě', 'è'],
    'i': ['ī', 'í', 'ǐ', 'ì'],
    'o': ['ō', 'ó', 'ǒ', 'ò'],
    'u': ['ū', 'ú', 'ǔ', 'ù'],
    'ü': ['ǖ', 'ǘ', 'ǚ', 'ǜ'],
  };

  // Map ngược: ký tự có dấu -> (nguyên âm gốc, thanh 1..4).
  static final Map<String, ({String base, int tone})> _reverse = () {
    final m = <String, ({String base, int tone})>{};
    _marks.forEach((base, variants) {
      for (var i = 0; i < variants.length; i++) {
        m[variants[i]] = (base: base, tone: i + 1);
      }
    });
    return m;
  }();

  /// Thanh điệu của một âm tiết pinyin (1..4, hoặc 0 nếu không dấu/nhẹ).
  static int toneOf(String syllable) {
    for (final ch in syllable.split('')) {
      final hit = _reverse[ch];
      if (hit != null) return hit.tone;
    }
    return 0;
  }

  /// Bỏ dấu thanh, trả về âm tiết "trần" (giữ ü).
  static String stripTones(String syllable) {
    final sb = StringBuffer();
    for (final ch in syllable.split('')) {
      final hit = _reverse[ch];
      sb.write(hit?.base ?? ch);
    }
    return sb.toString();
  }

  /// Đặt dấu thanh [tone] (1..4) lên âm tiết trần [base] theo quy tắc pinyin.
  /// tone = 0 -> giữ nguyên (thanh nhẹ).
  static String applyTone(String base, int tone) {
    final s = base.replaceAll('v', 'ü');
    if (tone < 1 || tone > 4) return s;

    int idx = s.indexOf('a');
    if (idx < 0) idx = s.indexOf('e');
    if (idx < 0 && s.contains('ou')) idx = s.indexOf('o');
    if (idx < 0) {
      // nguyên âm cuối cùng
      for (var i = s.length - 1; i >= 0; i--) {
        if (_marks.containsKey(s[i])) {
          idx = i;
          break;
        }
      }
    }
    if (idx < 0) return s; // không có nguyên âm

    final vowel = s[idx];
    final marked = _marks[vowel]?[tone - 1];
    if (marked == null) return s;
    return s.replaceRange(idx, idx + 1, marked);
  }

  /// Sinh 4 biến thể thanh (1..4) của một âm tiết, ví dụ "mā" -> [mā, má, mǎ, mà].
  static List<String> fourTones(String syllable) {
    final base = stripTones(syllable);
    return [for (var t = 1; t <= 4; t++) applyTone(base, t)];
  }
}
