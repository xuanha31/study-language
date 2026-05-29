/// Thông tin từng chữ Hán trong một từ (cho học sâu: pinyin + Hán Việt + nghĩa).
class CharInfo {
  final String char;
  final String reading; // pinyin có thanh điệu
  final String hanviet; // âm Hán Việt
  final String meaningVi;

  const CharInfo({
    required this.char,
    required this.reading,
    required this.hanviet,
    required this.meaningVi,
  });

  factory CharInfo.fromJson(Map<String, dynamic> json) => CharInfo(
        char: json['char'] as String? ?? '',
        reading: json['reading'] as String? ?? '',
        hanviet: json['hanviet'] as String? ?? '',
        meaningVi: json['meaning_vi'] as String? ?? '',
      );
}
