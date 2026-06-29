import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Cảnh gameplay kiểu Mario (E3): nấm lơ lửng trên đầu nhân vật, quái tiến tới từ
/// bên phải (chính là "đồng hồ" của câu — tốc độ = nhịp quái tới).
/// - Đúng  -> nhân vật **nhảy lên ăn nấm**, quái bỏ chạy.
/// - Sai/hết giờ -> **quái lao tới, nhân vật văng khỏi màn hình** (-1 mạng).
/// Vẽ canvas (placeholder thay sprite CC0 ở E8). Quiz UI là overlay Flutter.
class QuizGame extends FlameGame {
  late final Player player;
  late final Mushroom mushroom;
  Monster? monster;

  double speedFactor = 1.0; // nhịp nền theo tốc độ chơi
  double scroll = 0;
  bool _bossNext = false;

  double get groundLevel => size.y * 0.82;
  double get playerX => size.x * 0.30;

  @override
  Color backgroundColor() => const Color(0xFF9BD2F5);

  @override
  Future<void> onLoad() async {
    add(_Hills());
    add(_Clouds());
    add(_Ground());
    add(player = Player());
    add(mushroom = Mushroom());
    _spawnMonster();
  }

  @override
  void update(double dt) {
    super.update(dt);
    scroll += 40 * speedFactor * dt; // nền trôi nhẹ
  }

  /// Vị trí quái theo thời gian còn lại (1 = vừa xuất hiện ở xa, 0 = tới nơi).
  void setTimeRatio(double remaining01) {
    monster?.approach = (1 - remaining01).clamp(0.0, 1.0);
  }

  /// Câu mới: đặt lại nhân vật + nấm + quái mới (to hơn nếu là boss).
  void newQuestion({bool boss = false}) {
    _bossNext = boss;
    player.reset();
    mushroom.reset();
    _spawnMonster();
  }

  /// Trả lời đúng: nhảy lên ăn nấm, quái bỏ chạy.
  void onCorrect() {
    player.eat();
    monster?.flee();
  }

  /// Trả lời sai / hết giờ: quái lao tới, nhân vật văng khỏi màn hình.
  void onWrong() {
    monster?.lunge();
    player.knockOut();
  }

  void _spawnMonster() {
    monster?.removeFromParent();
    add(monster = Monster(boss: _bossNext));
  }
}

// ───────────────────────── Nền parallax ─────────────────────────

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
  static const _base = [
    [0.15, 50.0],
    [0.55, 28.0],
    [0.85, 70.0],
  ];
  @override
  void render(Canvas canvas) {
    final span = game.size.x + 160;
    for (final c in _base) {
      var x = (c[0] * game.size.x - game.scroll * 0.15) % span;
      if (x < -80) x += span;
      final o = Offset(x, c[1]);
      canvas.drawCircle(o, 20, _paint);
      canvas.drawCircle(o + const Offset(22, 6), 16, _paint);
      canvas.drawCircle(o + const Offset(-20, 6), 14, _paint);
    }
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
    const tile = 48.0;
    final off = -(game.scroll % tile);
    for (double x = off; x < game.size.x; x += tile) {
      canvas.drawRect(Rect.fromLTWH(x, y + 14, 2, game.size.y - y), _tile);
    }
  }
}

// ───────────────────────── Nhân vật ─────────────────────────

enum _PlayerState { idle, eat, ko }

class Player extends PositionComponent with HasGameReference<QuizGame> {
  static const _gravity = 2600.0;
  static const _eatV = -880.0;
  double _vy = 0, _vx = 0;
  double _t = 0;
  _PlayerState _state = _PlayerState.idle;
  bool _ate = false;

  final _body = Paint()..color = const Color(0xFFE53935);
  final _leg = Paint()..color = const Color(0xFF7A1F1C);

  double get _restY => game.groundLevel;

  @override
  Future<void> onLoad() async {
    size = Vector2(44, 60);
    anchor = Anchor.bottomCenter;
    position = Vector2(game.playerX, _restY);
  }

  void reset() {
    _state = _PlayerState.idle;
    _vy = 0;
    _vx = 0;
    _ate = false;
    position = Vector2(game.playerX, _restY);
  }

  void eat() {
    if (_state == _PlayerState.ko) return;
    _state = _PlayerState.eat;
    _ate = false;
    _vy = _eatV;
  }

  void knockOut() {
    _state = _PlayerState.ko;
    _vy = -1300;
    _vx = -260;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    switch (_state) {
      case _PlayerState.idle:
        position.x = game.playerX;
        position.y = _restY + sin(_t * 6) * 2;
        break;
      case _PlayerState.eat:
        _vy += _gravity * dt;
        position.y += _vy * dt;
        // nhảy vòng cung: đi lên thì tiến tới nấm, rơi xuống thì về chỗ cũ
        final ascending = _vy < 0;
        final tx = ascending ? game.mushroom.position.x : game.playerX;
        position.x += (tx - position.x) * min(1.0, dt * 8);
        if (!_ate && !ascending) {
          _ate = true; // tới đỉnh = chạm nấm
          game.mushroom.consume();
        }
        if (position.y >= _restY) {
          position.y = _restY;
          position.x = game.playerX;
          _state = _PlayerState.idle;
        }
        break;
      case _PlayerState.ko:
        _vy += _gravity * dt;
        position.x += _vx * dt;
        position.y += _vy * dt; // không chặn đất -> văng ra ngoài
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_state == _PlayerState.idle) {
      // chân nhún nhẹ
      canvas.drawRect(Rect.fromLTWH(size.x * 0.26, size.y - 10, 8, 12), _leg);
      canvas.drawRect(Rect.fromLTWH(size.x * 0.60, size.y - 10, 8, 12), _leg);
    }
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(10));
    canvas.drawRRect(rect, _body);
    final eye = Paint()..color = Colors.white;
    final scared = _state == _PlayerState.ko;
    canvas.drawCircle(Offset(size.x * 0.34, size.y * 0.34), scared ? 7 : 5, eye);
    canvas.drawCircle(Offset(size.x * 0.66, size.y * 0.34), scared ? 7 : 5, eye);
    final pupil = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(size.x * 0.34, size.y * 0.34), 2.5, pupil);
    canvas.drawCircle(Offset(size.x * 0.66, size.y * 0.34), 2.5, pupil);
  }
}

// ───────────────────────── Nấm (trên đầu) ─────────────────────────

class Mushroom extends PositionComponent with HasGameReference<QuizGame> {
  double _t = 0;
  bool _alive = true;
  double _pop = 0; // hiệu ứng khi bị ăn

  // Vị trí CỐ ĐỊNH trong cảnh (lơ lửng phía trước-trên nhân vật) — không bám theo.
  double get _baseX => game.size.x * 0.52;
  double get _baseY => game.groundLevel - 180;

  @override
  Future<void> onLoad() async {
    size = Vector2(36, 34);
    anchor = Anchor.center;
    position = Vector2(_baseX, _baseY);
  }

  void reset() {
    _alive = true;
    _pop = 0;
    position = Vector2(_baseX, _baseY);
  }

  void consume() {
    if (!_alive) return;
    _alive = false;
    _pop = 0.3;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_alive) {
      position.x = _baseX; // cố định, chỉ bồng bềnh dọc nhẹ
      position.y = _baseY + sin(_t * 3) * 4;
    } else if (_pop > 0) {
      _pop -= dt;
      position.y -= 80 * dt; // bắn lên khi bị ăn
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_alive && _pop <= 0) return; // đã ăn xong -> ẩn
    final opacity = _alive ? 1.0 : (_pop / 0.3).clamp(0.0, 1.0);
    final cap = Paint()..color = const Color(0xFFD32F2F).withValues(alpha: opacity);
    final stem = Paint()..color = const Color(0xFFFFF3E0).withValues(alpha: opacity);
    final spot = Paint()..color = Colors.white.withValues(alpha: opacity);
    // thân
    canvas.drawRect(Rect.fromLTWH(size.x * 0.3, size.y * 0.5, size.x * 0.4, size.y * 0.5), stem);
    // mũ
    canvas.drawArc(Rect.fromLTWH(0, 0, size.x, size.y), pi, pi, true, cap);
    // chấm trắng
    canvas.drawCircle(Offset(size.x * 0.35, size.y * 0.3), 3, spot);
    canvas.drawCircle(Offset(size.x * 0.62, size.y * 0.34), 2.5, spot);
  }
}

// ───────────────────────── Quái (đồng hồ) ─────────────────────────

enum _MonsterState { walk, flee, lunge }

class Monster extends PositionComponent with HasGameReference<QuizGame> {
  final bool boss;
  double approach = 0; // 0 = ở xa bên phải, 1 = tới sát nhân vật
  double _t = 0;
  _MonsterState _state = _MonsterState.walk;

  Monster({this.boss = false});

  final _body = Paint()..color = const Color(0xFF4A148C);
  final _spike = Paint()..color = const Color(0xFF311B92);

  double get _spawnX => game.size.x + 70;
  double get _reachX => game.playerX + size.x * 0.75; // dừng sát nhân vật

  @override
  Future<void> onLoad() async {
    final s = boss ? 1.6 : 1.0;
    size = Vector2(64 * s, 70 * s);
    anchor = Anchor.bottomCenter;
    position = Vector2(_spawnX, game.groundLevel);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    switch (_state) {
      case _MonsterState.walk:
        final target = _spawnX + (_reachX - _spawnX) * approach;
        position.x += (target - position.x) * min(1, dt * 8); // bám mượt
        position.y = game.groundLevel + sin(_t * 8) * 3; // lạch bạch
        break;
      case _MonsterState.flee:
        position.x += 520 * dt; // chạy ra phải
        if (position.x > game.size.x + 120) removeFromParent();
        break;
      case _MonsterState.lunge:
        position.x += (game.playerX - position.x) * min(1, dt * 12);
        position.y = game.groundLevel;
        if ((position.x - game.playerX).abs() < 6) {
          opacity_ -= dt * 3;
          if (opacity_ <= 0) removeFromParent();
        }
        break;
    }
  }

  double opacity_ = 1.0;

  void flee() => _state = _MonsterState.flee;
  void lunge() => _state = _MonsterState.lunge;

  @override
  void render(Canvas canvas) {
    final body = _state == _MonsterState.lunge
        ? (Paint()..color = _body.color.withValues(alpha: opacity_.clamp(0.0, 1.0)))
        : _body;
    final spike = _state == _MonsterState.lunge
        ? (Paint()..color = _spike.color.withValues(alpha: opacity_.clamp(0.0, 1.0)))
        : _spike;
    // gai
    for (var i = 0; i < 5; i++) {
      final x = size.x * (0.12 + i * 0.18);
      final path = Path()
        ..moveTo(x - 8, 6)
        ..lineTo(x, -12)
        ..lineTo(x + 8, 6)
        ..close();
      canvas.drawPath(path, spike);
    }
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(14));
    canvas.drawRRect(rect, body);
    // mắt giận + răng
    final eye = Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: opacity_.clamp(0.0, 1.0));
    canvas.drawCircle(Offset(size.x * 0.30, size.y * 0.34), size.x * 0.10, eye);
    canvas.drawCircle(Offset(size.x * 0.70, size.y * 0.34), size.x * 0.10, eye);
    final mouth = Paint()..color = Colors.white.withValues(alpha: opacity_.clamp(0.0, 1.0));
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(
          Rect.fromLTWH(size.x * (0.28 + i * 0.13), size.y * 0.62, size.x * 0.07, size.y * 0.1),
          mouth);
    }
  }
}
