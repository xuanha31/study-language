import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme cơ bản. E2-5: dùng Noto Sans SC (qua google_fonts, tải+cache runtime)
/// để chữ Hán hiển thị đẹp & đồng nhất; offline lần đầu sẽ fallback font hệ thống.
class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      colorSchemeSeed: const Color(0xFFE53935),
      useMaterial3: true,
      brightness: Brightness.light,
    );
    return base.copyWith(
      textTheme: GoogleFonts.notoSansScTextTheme(base.textTheme),
    );
  }
}
