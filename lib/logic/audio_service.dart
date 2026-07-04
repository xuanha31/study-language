import 'package:flutter_tts/flutter_tts.dart';

/// Phát âm tiếng Trung bằng TTS (E5). Bọc [FlutterTts], chịu lỗi và cho biết
/// máy có giọng tiếng Trung hay không (để UI báo người dùng thay vì im lặng).
class AudioService {
  final FlutterTts _tts = FlutterTts();
  bool enabled = true; // đồng bộ từ AppSettings.audioEnabled
  bool _inited = false;
  bool _zhAvailable = false;

  // Các mã ngôn ngữ tiếng Trung có thể có tuỳ máy/engine.
  static const _zhCandidates = [
    'zh-CN', 'zh', 'cmn-Hans-CN', 'zh-Hans-CN', 'zh-Hans', 'zh_CN'
  ];

  bool get chineseAvailable => _zhAvailable;

  Future<void> _ensureInit() async {
    if (_inited) return;
    _inited = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.45); // chậm để nghe rõ thanh điệu
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      for (final lang in _zhCandidates) {
        try {
          if ((await _tts.isLanguageAvailable(lang)) == true) {
            await _tts.setLanguage(lang);
            _zhAvailable = true;
            break;
          }
        } catch (_) {}
      }
    } catch (_) {
      // TTS không khả dụng -> để _zhAvailable=false, UI sẽ báo.
    }
  }

  /// Đọc [text]. Trả về true nếu đã phát; false nếu tắt/không có giọng tiếng Trung.
  Future<bool> speak(String text) async {
    if (!enabled || text.isEmpty) return false;
    await _ensureInit();
    if (!_zhAvailable) return false;
    try {
      await _tts.stop();
      await _tts.speak(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// "Chuẩn bị giọng đọc": kiểm tra engine có tiếng Trung không (E5-1/E5-2).
  Future<bool> prepareVoices() async {
    await _ensureInit();
    return _zhAvailable;
  }
}
