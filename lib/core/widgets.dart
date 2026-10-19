import 'package:flutter/material.dart';

import 'game_speed.dart';
import 'theme.dart';

/// Widget dùng chung cho giao diện mới (thẻ, progress, nút tròn, icon nấm...).

/// Số có dấu chấm ngăn nghìn: 1298 -> "1.298".
String fmtNum(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Chữ số Hán cho cấp HSK (1 -> 一). Ngoài 1..10 trả về số thường.
String hanziNumeral(int n) {
  const digits = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
  return (n >= 1 && n <= digits.length) ? digits[n - 1] : '$n';
}

/// Thanh tiến độ bo tròn.
class ProgressTrack extends StatelessWidget {
  final double value;
  final double height;
  final Color color;
  final Color trackColor;
  const ProgressTrack({
    super.key,
    required this.value,
    this.height = 6,
    this.color = AppColors.cinnabar,
    this.trackColor = AppColors.track,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        color: color,
        backgroundColor: trackColor,
      ),
    );
  }
}

/// Ô vuông kiểu con dấu chứa chữ Hán.
class SealBadge extends StatelessWidget {
  final String text;
  final double size;
  final bool filled;
  final double radius;
  const SealBadge(this.text, {super.key, this.size = 44, this.filled = false, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.cinnabar : AppColors.cinnabarSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        text,
        style: AppText.hanzi(size * 0.5,
            color: filled ? AppColors.card : AppColors.cinnabarDeep),
      ),
    );
  }
}

/// Nút icon tròn 44px (vùng chạm tối thiểu).
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color background;
  final Color color;
  final double size;
  final double iconSize;
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.background = AppColors.cinnabarSoft,
    this.color = AppColors.cinnabarDeep,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );
  }
}

/// Nhãn nhóm viết hoa nhỏ (VÒNG CHƠI, DỮ LIỆU...).
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(text.toUpperCase(), style: AppText.overline),
    );
  }
}

/// Bộ chọn tốc độ dạng viên thuốc 3 nấc (Chậm / Vừa / Nhanh).
class SpeedSelector extends StatelessWidget {
  final GameSpeed value;
  final ValueChanged<GameSpeed> onChanged;
  const SpeedSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.track,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final s in GameSpeed.values)
            Expanded(
              child: Semantics(
                selected: s == value,
                button: true,
                child: Material(
                  color: s == value ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onChanged(s),
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          s.labelVi,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: s == value ? FontWeight.w700 : FontWeight.w600,
                            color: s == value ? AppColors.ink : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Icon nấm (vẽ tay) — thay emoji 🍄.
class MushroomIcon extends StatelessWidget {
  final double size;
  final bool muted;
  const MushroomIcon({super.key, this.size = 18, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _MushroomPainter(muted));
  }
}

class _MushroomPainter extends CustomPainter {
  final bool muted;
  _MushroomPainter(this.muted);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cap = Paint()..color = muted ? const Color(0xFFB7A99A) : AppColors.cinnabar;
    final stem = Paint()..color = muted ? AppColors.disabled : const Color(0xFFE9D9BD);
    final spot = Paint()..color = AppColors.card;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.375, h * 0.48, w * 0.25, h * 0.32), Radius.circular(w * 0.08)),
      stem,
    );
    final capPath = Path()
      ..moveTo(w * 0.12, h * 0.52)
      ..arcTo(Rect.fromLTWH(w * 0.12, h * 0.16, w * 0.76, h * 0.72), 3.14159, 3.14159, false)
      ..close();
    canvas.drawPath(capPath, cap);
    if (!muted) {
      canvas.drawCircle(Offset(w * 0.38, h * 0.34), w * 0.07, spot);
      canvas.drawCircle(Offset(w * 0.62, h * 0.37), w * 0.055, spot);
    }
  }

  @override
  bool shouldRepaint(_MushroomPainter old) => old.muted != muted;
}

/// Chip số liệu nhỏ (mạng, nấm) trên HUD game.
class HudChip extends StatelessWidget {
  final Widget icon;
  final String text;
  final String semanticLabel;
  const HudChip({super.key, required this.icon, required this.text, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 5),
            Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Báo khi vòng chơi phải bỏ câu Nghe/Thanh điệu vì máy thiếu giọng tiếng Trung.
const noVoiceSnack = SnackBar(
  content: Text('Máy chưa có giọng đọc tiếng Trung — vòng này tạm bỏ câu Nghe/Thanh điệu '
      '(Cài đặt → Chuẩn bị giọng đọc)'),
  duration: Duration(seconds: 4),
);
