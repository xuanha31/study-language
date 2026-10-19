import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Hiệu ứng âm thanh + rung trong vòng chơi (file ở assets/sfx, sinh bằng
/// tools/make_sfx.py). Chịu lỗi: máy không phát được thì im lặng, không crash.
enum Sfx { correct, wrong, jump, hit, life, powerup, win, lose }

class SfxService {
  bool enabled = true; // đồng bộ từ AppSettings.sfxEnabled

  // Mỗi hiệu ứng một player riêng để các tiếng chồng lên nhau được (đúng + nhảy).
  final Map<Sfx, AudioPlayer> _players = {};

  AudioPlayer _player(Sfx s) => _players.putIfAbsent(s, () {
    final p = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    // Không giành audio focus -> không cắt ngang giọng đọc TTS.
    p.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
    return p;
  });

  Future<void> play(Sfx s) async {
    _haptic(s);
    if (!enabled) return;
    try {
      final p = _player(s);
      await p.stop();
      await p.play(AssetSource('sfx/${s.name}.wav'), volume: 0.6);
    } catch (_) {
      // Thiếu codec/thiết bị âm thanh -> bỏ qua.
    }
  }

  void _haptic(Sfx s) {
    if (!enabled) return;
    switch (s) {
      case Sfx.wrong:
      case Sfx.lose:
        HapticFeedback.heavyImpact();
      case Sfx.hit:
        HapticFeedback.mediumImpact();
      case Sfx.correct:
      case Sfx.life:
        HapticFeedback.lightImpact();
      default:
        break;
    }
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}
