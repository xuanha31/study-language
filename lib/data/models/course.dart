/// Một khóa học (HSK1..HSK6) — lấy từ content/manifest.json.
class Course {
  final String code;
  final String titleVi;
  final int version;
  final String url; // tên file json trong content/
  final int vocabCount;
  final int lessonSize;

  const Course({
    required this.code,
    required this.titleVi,
    required this.version,
    required this.url,
    required this.vocabCount,
    required this.lessonSize,
  });

  /// Số bài = ceil(vocabCount / lessonSize).
  int get lessonCount => (vocabCount / lessonSize).ceil();

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        code: json['code'] as String,
        titleVi: json['title_vi'] as String? ?? json['code'] as String,
        version: json['version'] as int? ?? 1,
        url: json['url'] as String? ?? '',
        vocabCount: json['vocabCount'] as int? ?? 0,
        lessonSize: json['lessonSize'] as int? ?? 20,
      );
}
