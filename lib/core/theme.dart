import 'package:flutter/material.dart';

/// Theme cơ bản. Lưu ý E2-5: nên nhúng font CJK (Noto Sans SC) để chữ Hán
/// hiển thị đồng nhất mọi máy; hiện dùng font hệ thống (đa số máy render CJK ổn).
class AppTheme {
  static ThemeData get light => ThemeData(
        colorSchemeSeed: const Color(0xFFE53935),
        useMaterial3: true,
        brightness: Brightness.light,
      );
}
