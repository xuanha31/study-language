import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Cảnh platformer tối giản cho gameplay HƯỚNG A (dừng để hỏi).
/// Vẽ bằng canvas (placeholder) — thay sprite CC0 ở task E8.
/// Quiz UI là overlay Flutter phía trên (xem GameScreen).
class QuizGame extends FlameGame {
  late final Player player;

  double get groundLevel => size.y * 0.74; // mốc mặt đất (y)

  @override
  Color backgroundColor() => const Color(0xFF9BD2F5); // trời xanh

  @override
  Future<void> onLoad() async {
    add(_Ground());
    add(player = Player());
  }

  /// Trả lời đúng: nhân vật nhảy ăn nấm.
  void onCorrect() {
    player.jump();
    add(_Mushroom(Vector2(player.position.x, groundLevel - 90)));
  }

  /// Trả lời sai: nhân vật giật/đỏ mặt.
  void onWrong() => player.hit();
}

class _Ground extends PositionComponent with HasGameReference<QuizGame> {
  final _grass = Paint()..color = const Color(0xFF6AbE4F);
  final _soil = Paint()..color = const Color(0xFF8D6E3A);

  @override
  void render(Canvas canvas) {
    final y = game.groundLevel;
    canvas.drawRect(Rect.fromLTWH(0, y, game.size.x, 14), _grass);
    canvas.drawRect(Rect.fromLTWH(0, y + 14, game.size.x, game.size.y - y), _soil);
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
      // nhún nhẹ khi đứng cho sinh động
      position.y = rest + sin(_t * 6) * 2;
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
    final paint = _hitFlash > 0 ? (Paint()..color = const Color(0xFFB71C1C)) : _body;
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(10));
    canvas.drawRRect(rect, paint);
    // mắt
    final eye = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.x * 0.34, size.y * 0.34), 5, eye);
    canvas.drawCircle(Offset(size.x * 0.66, size.y * 0.34), 5, eye);
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
