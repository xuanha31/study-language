import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../logic/shop/shop_catalog.dart';

/// Cảnh gameplay kiểu Mario (E3): nấm lơ lửng phía trước-trên nhân vật, quái tiến
/// tới từ bên phải (chính là "đồng hồ" của câu — tốc độ = nhịp quái tới).
/// - Đúng  -> nhân vật **nhảy lên ăn nấm**, quái bỏ chạy (boss: trúng đòn, -1 HP).
/// - Sai/hết giờ -> **quái lao tới, nhân vật bị hất văng** (-1 mạng).
/// Sprite: Kenney "New Platformer Pack" (CC0) — nhân vật/phong cảnh chọn ở cửa hàng.
/// Vương miện + thanh HP của boss vẽ bằng canvas. Quiz UI là widget Flutter bên dưới.
class QuizGame extends FlameGame {
  final String character; // id nhân vật (ShopCatalog.characters)
  final SceneStyle style;

  QuizGame({String character = 'beige', String scene = 'hills'})
      : character = ShopCatalog.characterOf(character),
        style = ShopCatalog.styleOf(scene);

  late final Player player;
  late final Mushroom mushroom;
  Monster? monster;

  double speedFactor = 1.0; // nhịp nền theo tốc độ chơi
  double scroll = 0;
  int bossHp = 0;
  int bossMax = 0;

  bool _pendingBoss = false; // câu đầu gọi trước khi onLoad xong
  double _shakeT = 0;
  double _shakeAmp = 0;
  final _rng = Random();

  /// Mép dưới thanh HUD (widget Flutter phủ lên cảnh) — màn hình đặt theo safe area.
  double hudBottom = 70;

  double get groundLevel => size.y * 0.80;
  double get playerX => size.x * 0.26;

  /// Hệ số co theo khoảng trống giữa HUD và mặt đất: máy màn thấp thu nhỏ nhân vật,
  /// quái, nấm để không chạm HUD (thiết kế gốc cho ~200dp trống).
  double get unit => ((groundLevel - hudBottom) / 200).clamp(0.78, 1.0);

  /// Nấm: phía trên đầu, luôn nằm dưới thanh HUD để cú nhảy không chạm HUD.
  double get mushroomY => max(groundLevel - 150 * unit, hudBottom + 26 * unit);

  static const _dir = 'kenney';

  Sprite sprite(String path) => Sprite(images.fromCache('$_dir/$path.png'));

  @override
  Color backgroundColor() => Colors.white; // phần trên của nền Kenney là trời trắng

  @override
  Future<void> onLoad() async {
    final enemies = [...style.enemies, 'slime_block'];
    await images.loadAll([
      for (final f in ['walk_a', 'walk_b', 'jump', 'hit']) '$_dir/characters/${character}_$f.png',
      for (final e in enemies)
        for (final f in ['walk_a', 'walk_b']) '$_dir/enemies/${e}_$f.png',
      '$_dir/enemies/slime_block_jump.png',
      '$_dir/backgrounds/${style.background}.png',
      '$_dir/tiles/terrain_${style.terrain}_top.png',
      '$_dir/tiles/terrain_${style.terrain}_center.png',
      '$_dir/tiles/mushroom_red.png',
    ]);
    add(_Backdrop());
    add(_Clouds());
    add(_Ground());
    add(player = Player());
    add(mushroom = Mushroom());
    _spawnMonster(boss: _pendingBoss);
  }

  @override
  void update(double dt) {
    super.update(dt);
    scroll += 40 * speedFactor * dt; // nền trôi nhẹ
    if (_shakeT > 0) _shakeT -= dt;
  }

  @override
  void render(Canvas canvas) {
    if (_shakeT <= 0) {
      super.render(canvas);
      return;
    }
    final a = _shakeAmp * (_shakeT / 0.3).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate((_rng.nextDouble() * 2 - 1) * a, (_rng.nextDouble() * 2 - 1) * a);
    super.render(canvas);
    canvas.restore();
  }

  void shake([double amp = 6]) {
    _shakeT = 0.3;
    _shakeAmp = amp;
  }

  /// Vị trí quái theo thời gian còn lại (1 = vừa xuất hiện ở xa, 0 = tới nơi).
  void setTimeRatio(double remaining01) {
    monster?.approach = (1 - remaining01).clamp(0.0, 1.0);
  }

  void setBoss(int hp, int maxHp) {
    bossHp = hp;
    bossMax = maxHp;
  }

  /// Câu mới: đặt lại nhân vật + nấm; boss còn sống thì giữ nguyên (nhiều câu).
  void newQuestion({bool boss = false}) {
    if (!isLoaded) {
      _pendingBoss = boss;
      return;
    }
    player.reset();
    mushroom.reset();
    final m = monster;
    if (boss && m != null && m.boss && m.alive) {
      m.resetWalk();
    } else {
      _spawnMonster(boss: boss);
    }
  }

  /// Trả lời đúng: nhảy lên ăn nấm; quái bỏ chạy, boss trúng đòn.
  void onCorrect() {
    player.eat();
    final m = monster;
    if (m == null) return;
    if (m.boss) {
      m.hit(defeated: bossHp <= 0);
      shake(bossHp <= 0 ? 10 : 6);
    } else {
      m.flee();
    }
  }

  /// Trả lời sai / hết giờ: quái lao tới, nhân vật bị hất văng.
  void onWrong() {
    monster?.lunge();
    player.knockOut();
    shake(4);
  }

  void _spawnMonster({required bool boss}) {
    monster?.removeFromParent();
    final kind = boss ? 'slime_block' : style.enemies[_rng.nextInt(style.enemies.length)];
    add(monster = Monster(kind: kind, boss: boss));
  }
}

// ───────────────────────── Nền ─────────────────────────

/// Nền Kenney lặp ngang (parallax chậm) + dải trời xanh phủ phần trắng phía trên.
class _Backdrop extends PositionComponent with HasGameReference<QuizGame> {
  late final Sprite _bg = game.sprite('backgrounds/${game.style.background}');

  @override
  void render(Canvas canvas) {
    final h = game.groundLevel + 30;
    final w = _bg.srcSize.x * h / _bg.srcSize.y;
    final off = -(game.scroll * 0.25) % w;
    for (double x = off - w; x < game.size.x + w; x += w) {
      _bg.render(canvas, position: Vector2(x, game.groundLevel + 30 - h), size: Vector2(w + 1, h));
    }
    final sky = Rect.fromLTWH(0, 0, game.size.x, h * 0.55);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB9DDF6), Color(0x00FFFFFF)],
        ).createShader(sky),
    );
  }
}

class _Clouds extends PositionComponent with HasGameReference<QuizGame> {
  final _paint = Paint()..color = Colors.white.withValues(alpha: 0.95);
  // [x tương đối, y tương đối theo chiều cao cảnh] — nằm dưới vùng HUD.
  static const _base = [
    [0.15, 0.34],
    [0.55, 0.27],
    [0.85, 0.40],
  ];
  @override
  void render(Canvas canvas) {
    final span = game.size.x + 160;
    for (final c in _base) {
      var x = (c[0] * game.size.x - game.scroll * 0.1) % span;
      if (x < -80) x += span;
      final o = Offset(x, c[1] * game.size.y);
      canvas.drawCircle(o, 15, _paint);
      canvas.drawCircle(o + const Offset(17, 5), 12, _paint);
      canvas.drawCircle(o + const Offset(-15, 5), 10, _paint);
    }
  }
}

/// Mặt đất ghép tile: hàng trên là mép cỏ/cát, bên dưới là đất; trôi theo nhịp chạy.
class _Ground extends PositionComponent with HasGameReference<QuizGame> {
  late final Sprite _top = game.sprite('tiles/terrain_${game.style.terrain}_top');
  late final Sprite _center = game.sprite('tiles/terrain_${game.style.terrain}_center');

  @override
  void render(Canvas canvas) {
    const tile = 48.0;
    final y0 = game.groundLevel;
    final off = -(game.scroll % tile);
    final t = Vector2.all(tile + 0.5); // +0.5 tránh khe hở giữa tile khi scale
    for (double x = off; x < game.size.x; x += tile) {
      _top.render(canvas, position: Vector2(x, y0), size: t);
      for (double y = y0 + tile; y < game.size.y; y += tile) {
        _center.render(canvas, position: Vector2(x, y), size: t);
      }
    }
  }
}

// ───────────────────────── Nhân vật ─────────────────────────

enum _PlayerState { run, eat, ko }

class Player extends PositionComponent with HasGameReference<QuizGame> {
  static const _gravity = 2400.0;
  double _vy = 0, _vx = 0;
  double _t = 0;
  double _opacity = 1;
  _PlayerState _state = _PlayerState.run;
  bool _ate = false;

  late final Sprite _walkA, _walkB, _jump, _hit;

  double get _restY => game.groundLevel;

  @override
  Future<void> onLoad() async {
    final c = 'characters/${game.character}';
    _walkA = game.sprite('${c}_walk_a');
    _walkB = game.sprite('${c}_walk_b');
    _jump = game.sprite('${c}_jump');
    _hit = game.sprite('${c}_hit');
    size = Vector2.all(76 * game.unit);
    anchor = Anchor.bottomCenter;
    position = Vector2(game.playerX, _restY);
  }

  void reset() {
    _state = _PlayerState.run;
    _vy = 0;
    _vx = 0;
    _ate = false;
    _opacity = 1;
    angle = 0;
    position = Vector2(game.playerX, _restY);
  }

  void eat() {
    if (_state == _PlayerState.ko) return;
    _state = _PlayerState.eat;
    _ate = false;
    // Nhảy vừa đủ để đầu chạm nấm (không vọt lên đụng HUD). Đầu ≈ 75% khung sprite.
    final rise = (_restY - game.mushroomY) - size.y * 0.75 + 14;
    _vy = -sqrt(2 * _gravity * max(rise, 40));
  }

  /// Bị hất văng sang trái theo cung thấp, xoay và mờ dần (không bay lên HUD).
  void knockOut() {
    _state = _PlayerState.ko;
    _vy = -520;
    _vx = -380;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt * (0.6 + 0.4 * game.speedFactor);
    switch (_state) {
      case _PlayerState.run:
        position.x = game.playerX;
        position.y = _restY;
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
          _state = _PlayerState.run;
        }
        break;
      case _PlayerState.ko:
        _vy += _gravity * dt;
        position.x += _vx * dt;
        position.y = min(position.y + _vy * dt, _restY + size.y); // rơi xuống đất rồi lún
        angle -= dt * 9;
        _opacity = max(0, _opacity - dt * 1.6);
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0) return;
    final frame = switch (_state) {
      _PlayerState.run => (_t * 8).floor().isEven ? _walkA : _walkB, // 2 frame chạy
      _PlayerState.eat => _jump,
      _PlayerState.ko => _hit,
    };
    frame.render(canvas,
        size: size, overridePaint: Paint()..color = Colors.white.withValues(alpha: _opacity));
  }
}

// ───────────────────────── Nấm (trên đầu) ─────────────────────────

class Mushroom extends PositionComponent with HasGameReference<QuizGame> {
  double _t = 0;
  bool _alive = true;
  double _pop = 0; // hiệu ứng khi bị ăn
  late final Sprite _sprite;

  // Vị trí CỐ ĐỊNH trong cảnh (lơ lửng phía trước-trên nhân vật) — không bám theo.
  double get _baseX => game.size.x * 0.46;
  double get _baseY => game.mushroomY;

  @override
  Future<void> onLoad() async {
    _sprite = game.sprite('tiles/mushroom_red');
    final ratio = _sprite.srcSize.y / _sprite.srcSize.x;
    size = Vector2(42, 42 * ratio) * game.unit;
    anchor = Anchor.center;
    position = Vector2(_baseX, _baseY);
  }

  void reset() {
    _alive = true;
    _pop = 0;
    scale = Vector2.all(1);
    position = Vector2(_baseX, _baseY);
  }

  void consume() {
    if (!_alive) return;
    _alive = false;
    _pop = 0.35;
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
      position.y -= 60 * dt; // bắn lên khi bị ăn
      scale = Vector2.all(1 + (0.35 - _pop) * 1.6);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_alive && _pop <= 0) return; // đã ăn xong -> ẩn
    final opacity = _alive ? 1.0 : (_pop / 0.35).clamp(0.0, 1.0);
    if (_alive) {
      // bóng đổ mờ dưới nấm
      canvas.drawOval(Rect.fromLTWH(size.x * 0.15, size.y + 8, size.x * 0.7, 5),
          Paint()..color = const Color(0x22000000));
    }
    _sprite.render(canvas,
        size: size, overridePaint: Paint()..color = Colors.white.withValues(alpha: opacity));
  }
}

// ───────────────────────── Quái (đồng hồ) ─────────────────────────

enum _MonsterState { walk, flee, lunge, hit, dead }

class Monster extends PositionComponent with HasGameReference<QuizGame> {
  final String kind; // tên sprite quái trong kenney/enemies
  final bool boss;
  double approach = 0; // 0 = ở mép phải, 1 = tới sát nhân vật
  double _t = 0;
  double _flash = 0; // nháy trắng khi trúng đòn
  double _opacity = 1;
  double _hitT = 0;
  _MonsterState _state = _MonsterState.walk;
  late final Sprite _a, _b;
  Sprite? _hurt;

  Monster({required this.kind, this.boss = false});

  bool get alive => _state != _MonsterState.dead;

  // Đứng ở mép phải (luôn nhìn thấy) rồi tiến dần tới nhân vật.
  double get _spawnX => game.size.x - size.x * 0.5 - 4;
  double get _reachX => game.playerX + 26 * game.unit + size.x * 0.42; // dừng sát nhân vật

  @override
  Future<void> onLoad() async {
    _a = game.sprite('enemies/${kind}_walk_a');
    _b = game.sprite('enemies/${kind}_walk_b');
    if (boss) _hurt = game.sprite('enemies/slime_block_jump');
    size = Vector2.all((boss ? 104 : 66) * game.unit);
    anchor = Anchor.bottomCenter;
    // Xuất hiện từ ngoài màn hình rồi trượt vào vị trí.
    position = Vector2(game.size.x + size.x, game.groundLevel + 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt * (0.6 + 0.4 * game.speedFactor);
    if (_flash > 0) _flash -= dt;
    final ground = game.groundLevel + 2; // sprite có viền trong suốt nhỏ ở đáy
    switch (_state) {
      case _MonsterState.walk:
        final target = _spawnX + (_reachX - _spawnX) * approach;
        position.x += (target - position.x) * min(1, dt * (boss ? 4 : 8)); // bám mượt
        position.y = ground;
        break;
      case _MonsterState.flee:
        position.x += 520 * dt; // chạy ra phải
        scale.x = -1; // quay lưng bỏ chạy
        if (position.x > game.size.x + 120) removeFromParent();
        break;
      case _MonsterState.lunge:
        position.x += (_reachX - 14 - position.x) * min(1, dt * 12);
        position.y = ground;
        if (!boss && (position.x - (_reachX - 14)).abs() < 6) {
          _opacity -= dt * 3;
          if (_opacity <= 0) removeFromParent();
        }
        break;
      case _MonsterState.hit:
        _hitT -= dt;
        // bị đẩy lùi nhưng không quá mép phải (vẫn thấy boss + thanh HP)
        if (_hitT > 0) position.x = min(position.x + 260 * dt, _spawnX);
        position.y = ground;
        if (_hitT <= 0) _state = _MonsterState.walk;
        break;
      case _MonsterState.dead:
        position.y += 260 * dt;
        angle += dt * 4;
        _opacity -= dt * 1.4;
        if (_opacity <= 0) removeFromParent();
        break;
    }
  }

  void resetWalk() {
    if (!alive) return;
    _state = _MonsterState.walk;
    scale.x = 1;
    approach = 0;
  }

  void flee() => _state = _MonsterState.flee;
  void lunge() {
    if (alive) _state = _MonsterState.lunge;
  }

  /// Boss trúng đòn: nháy trắng + lùi lại; hết HP thì gục.
  void hit({required bool defeated}) {
    _flash = 0.25;
    if (defeated) {
      _state = _MonsterState.dead;
    } else {
      _state = _MonsterState.hit;
      _hitT = 0.3;
    }
  }

  @override
  void render(Canvas canvas) {
    final moving = _state == _MonsterState.walk || _state == _MonsterState.flee;
    final hurt = _state == _MonsterState.hit || _state == _MonsterState.dead;
    final frame = hurt && _hurt != null
        ? _hurt!
        : (moving ? ((_t * 6).floor().isEven ? _a : _b) : _a);
    final paint = Paint()..color = Colors.white.withValues(alpha: _opacity.clamp(0.0, 1.0));
    if (_flash > 0) {
      paint.colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: (_flash / 0.25) * 0.85), BlendMode.srcATop);
    }
    frame.render(canvas, size: size, overridePaint: paint);
    if (boss) _renderBossExtras(canvas, size.x, size.y);
  }

  void _renderBossExtras(Canvas canvas, double w, double h) {
    final a = _opacity.clamp(0.0, 1.0);
    Paint p(Color c) => Paint()..color = c.withValues(alpha: a);
    // Vương miện đặt trên đỉnh khối slime (đỉnh nội dung ≈ 12% khung sprite)
    final top = h * 0.14;
    final crown = Path()
      ..moveTo(w * 0.30, top)
      ..lineTo(w * 0.32, top - h * 0.20)
      ..lineTo(w * 0.41, top - h * 0.09)
      ..lineTo(w * 0.50, top - h * 0.24)
      ..lineTo(w * 0.59, top - h * 0.09)
      ..lineTo(w * 0.68, top - h * 0.20)
      ..lineTo(w * 0.70, top)
      ..close();
    canvas.drawPath(crown, p(const Color(0xFFFFC107)));
    canvas.drawPath(
        crown,
        p(const Color(0xFF353541))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(Offset(w * 0.50, top - h * 0.07), 4, p(const Color(0xFFE53935)));

    // Thanh HP phía trên vương miện: mỗi ô = 1 câu đúng cần để hạ boss
    final maxHp = max(1, game.bossMax);
    final hp = game.bossHp.clamp(0, maxHp);
    const gap = 3.0;
    final barW = w * 0.9;
    final cellW = (barW - gap * (maxHp - 1)) / maxHp;
    final barTop = top - h * 0.36;
    for (var i = 0; i < maxHp; i++) {
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.05 + i * (cellW + gap), barTop, cellW, 9), const Radius.circular(4.5));
      canvas.drawRRect(r, p(const Color(0x66000000)));
      if (i < hp) canvas.drawRRect(r.deflate(1.5), p(const Color(0xFFE53935)));
    }
  }
}
