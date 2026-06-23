import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Cảnh platformer cho gameplay HƯỚNG A (dừng để hỏi) — E3-6.
/// Nền cuộn parallax (mây/đồi/mặt đất); giữa các câu nhân vật chạy tới "trạm" kế
/// (`runToNext`); câu boss có quái xuất hiện (`showBoss`). Vẽ canvas (placeholder
/// thay sprite CC0 ở E8). Quiz UI là overlay Flutter phía trên (xem GameScreen).
class QuizGame extends FlameGame {
  late final Player player;

  double scroll = 0; // tổng quãng nền đã cuộn (px)
  double _runRemaining = 0; // thời gian còn đang "chạy tới trạm kế"
  Boss? _boss;

  double get groundLevel => size.y * 0.74;
  bool get running => _runRemaining > 0;

  @override
  Color backgroundColor() => const Color(0xFF9BD2F5); // trời xanh

  @override
  Future<void> onLoad() async {
    add(_Hills());
    add(_Clouds());
    add(_Ground());
    add(player = Player());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_runRemaining > 0) _runRemaining -= dt;
    final speed = running ? 420.0 : 36.0; // px/s: chạy nhanh / trôi nhẹ
    scroll += speed * dt;
  }

  /// Chạy tới trạm câu hỏi kế (gọi khi chuyển câu).
  void runToNext() => _runRemaining = 0.7;

  /// Trả lời đúng: nhân vật nhảy ăn nấm.
  void onCorrect() {
    player.jump();
    add(_Mushroom(Vector2(player.position.x + 60, groundLevel - 90)));
  }

  /// Trả lời sai: nhân vật giật/đỏ mặt.
  void onWrong() => player.hit();

  /// Câu boss: cho quái xuất hiện từ bên phải.
  void showBoss() {
    if (_boss != null) return;
    add(_boss = Boss());
  }
}

class _Hills extends PositionComponent with HasGameReference<QuizGame> {
  final _paint = Paint()..color = const Color(0xFF7FC47F);

  @override
  void render(Canvas canvas) {
    const wave = 220.0;
    final y = game.groundLevel;
    final off = -(game.scroll * 0.3) % wave;
    for (double x = off - wave; x < game.size.x + wave; x += wave) {
      canvas.drawCircle(Offset(x + wave / 2, y), wave * 0.55, _paint);
    }
  }
}

class _Clouds extends PositionComponent with HasGameReference<QuizGame> {
  final _paint = Paint()..color = Colors.white.withValues(alpha: 0.9);
  // vị trí gốc (x theo tỉ lệ rộng, y tuyệt đối)
  static const _base = [
    [0.15, 70.0],
    [0.55, 40.0],
    [0.85, 100.0],
  ];

  @override
  void render(Canvas canvas) {
    final span = game.size.x + 160;
    for (final c in _base) {
      final bx = c[0] * game.size.x;
      var x = (bx - game.scroll * 0.15) % span;
      if (x < -80) x += span;
      _cloud(canvas, Offset(x, c[1]));
    }
  }

  void _cloud(Canvas canvas, Offset o) {
    canvas.drawCircle(o, 20, _paint);
    canvas.drawCircle(o + const Offset(22, 6), 16, _paint);
    canvas.drawCircle(o + const Offset(-20, 6), 14, _paint);
  }
}

class _Ground extends PositionComponent with HasGameReference<QuizGame> {
  final _grass = Paint()..color = const Color(0xFF6AbE4F);
  final _soil = Paint()..color = const Color(0xFF8D6E3A);
  final _tile = Paint()..color = const Color(0x22000000);

  @override
  void render(Canvas canvas) {
    final y = game.groundLevel;
    canvas.drawRect(Rect.fromLTWH(0, y, game.size.x, 14), _grass);
    canvas.drawRect(Rect.fromLTWH(0, y + 14, game.size.x, game.size.y - y), _soil);
    // vạch gạch chạy theo scroll cho cảm giác chuyển động
    const tile = 48.0;
    final off = -(game.scroll % tile);
    for (double x = off; x < game.size.x; x += tile) {
      canvas.drawRect(Rect.fromLTWH(x, y + 14, 2, game.size.y - y), _tile);
    }
  }
}

class Player extends PositionComponent with HasGameReference<QuizGame> {
  static const _gravity = 2400.0;
  static const _jumpV = -900.0;
  double _vy = 0;
  bool _onGround = true;
  double _t = 0;
  double _hitFlash = 0;

  final _body = Paint()..color = const Color(0xFFE53935);
  final _leg = Paint()..color = const Color(0xFF7A1F1C);

  @override
  Future<void> onLoad() async {
    size = Vector2(44, 56);
    anchor = Anchor.bottomCenter;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_hitFlash > 0) _hitFlash -= dt;

    position.x = game.size.x * 0.32;
    final rest = game.groundLevel;
    if (!_onGround) {
      _vy += _gravity * dt;
      position.y += _vy * dt;
      if (position.y >= rest) {
        position.y = rest;
        _vy = 0;
        _onGround = true;
      }
    } else {
      position.y = rest + sin(_t * 6) * 2; // nhún nhẹ khi đứng
    }
  }

  void jump() {
    if (_onGround) {
      _vy = _jumpV;
      _onGround = false;
    }
  }

  void hit() => _hitFlash = 0.4;

  @override
  void render(Canvas canvas) {
    // chân chạy (đung đưa khi đang chạy)
    if (game.running && _onGround) {
      final swing = sin(_t * 22) * 6;
      canvas.drawRect(Rect.fromLTWH(size.x * 0.28 + swing, size.y - 10, 8, 12), _leg);
      canvas.drawRect(Rect.fromLTWH(size.x * 0.58 - swing, size.y - 10, 8, 12), _leg);
    }
    final paint = _hitFlash > 0 ? (Paint()..color = const Color(0xFFB71C1C)) : _body;
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(10));
    canvas.drawRRect(rect, paint);
    final eye = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.x * 0.34, size.y * 0.34), 5, eye);
    canvas.drawCircle(Offset(size.x * 0.66, size.y * 0.34), 5, eye);
  }
}

/// Quái boss (câu 20): trượt vào từ bên phải rồi đứng đối diện nhân vật.
class Boss extends PositionComponent with HasGameReference<QuizGame> {
  double _t = 0;
  final _body = Paint()..color = const Color(0xFF4A148C);
  final _spike = Paint()..color = const Color(0xFF311B92);

  @override
  Future<void> onLoad() async {
    size = Vector2(90, 96);
    anchor = Anchor.bottomCenter;
    position = Vector2(game.size.x + 80, game.groundLevel);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final target = game.size.x * 0.78;
    if (position.x > target) {
      position.x = max(target, position.x - 240 * dt);
    }
    position.y = game.groundLevel + sin(_t * 3) * 4;
  }

  @override
  void render(Canvas canvas) {
    // gai trên đầu
    for (var i = 0; i < 5; i++) {
      final x = size.x * (0.12 + i * 0.18);
      final path = Path()
        ..moveTo(x - 8, 6)
        ..lineTo(x, -12)
        ..lineTo(x + 8, 6)
        ..close();
      canvas.drawPath(path, _spike);
    }
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(14));
    canvas.drawRRect(rect, _body);
    // mắt giận dữ
    final eye = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawCircle(Offset(size.x * 0.32, size.y * 0.32), 8, eye);
    canvas.drawCircle(Offset(size.x * 0.68, size.y * 0.32), 8, eye);
    final pupil = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(size.x * 0.32, size.y * 0.34), 4, pupil);
    canvas.drawCircle(Offset(size.x * 0.68, size.y * 0.34), 4, pupil);
  }
}

class _Mushroom extends PositionComponent {
  double _life = 0.9;
  _Mushroom(Vector2 pos) {
    position = pos;
    size = Vector2(28, 26);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.y -= 60 * dt; // bay lên
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final opacity = (_life / 0.9).clamp(0.0, 1.0);
    final cap = Paint()..color = const Color(0xFFD32F2F).withValues(alpha: opacity);
    final stem = Paint()..color = const Color(0xFFFFF3E0).withValues(alpha: opacity);
    canvas.drawRect(Rect.fromLTWH(size.x * 0.3, size.y * 0.5, size.x * 0.4, size.y * 0.5), stem);
    canvas.drawArc(Rect.fromLTWH(0, 0, size.x, size.y), pi, pi, true, cap);
  }
}
