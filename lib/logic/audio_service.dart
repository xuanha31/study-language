import 'package:flutter_tts/flutter_tts.dart';

/// Phát âm tiếng Trung bằng TTS (E5). Bọc [FlutterTts], chịu lỗi:
/// nếu thiết bị không có engine TTS tiếng Trung thì im lặng, không crash.
class AudioService {
  final FlutterTts _tts = FlutterTts();
  bool enabled = true; // đồng bộ từ AppSettings.audioEnabled
  bool _inited = false;

  Future<void> _ensureInit() async {
    if (_inited) return;
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.45); // chậm hơn để nghe rõ thanh điệu
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _inited = true;
    } catch (_) {
      // TTS không khả dụng -> bỏ qua, các lần speak sau sẽ no-op.
    }
  }

  /// Đọc [text] bằng giọng tiếng Trung. No-op nếu audio đang tắt.
  Future<void> speak(String text) async {
    if (!enabled || text.isEmpty) return;
    try {
      await _ensureInit();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// "Chuẩn bị giọng đọc": kiểm tra engine có tiếng Trung không (E5-1/E5-2).
  Future<bool> prepareVoices() async {
    try {
      await _ensureInit();
      final langs = await _tts.getLanguages;
      if (langs is List) {
        return langs.any((l) => l.toString().toLowerCase().startsWith('zh'));
      }
    } catch (_) {}
    return false;
  }
}
