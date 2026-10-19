import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bảng màu "giấy dó & son đỏ" (xem artboard "Hệ thống giao diện" trên canvas thiết kế).
class AppColors {
  static const paper = Color(0xFFF5EFE3); // nền
  static const card = Color(0xFFFFFCF6); // thẻ / panel
  static const ink = Color(0xFF221C18); // chữ chính
  static const inkSoft = Color(0xFF62574D); // chữ phụ
  static const inkMuted = Color(0xFF8A7F74); // icon phụ / disabled
  static const line = Color(0xFFE6DCCB); // viền
  static const track = Color(0xFFEFE6D6); // rãnh progress, divider
  static const disabled = Color(0xFFD8CCB8);

  static const cinnabar = Color(0xFFB8322A); // primary
  static const cinnabarDeep = Color(0xFF8F2620); // chữ trên nền nhạt
  static const cinnabarSoft = Color(0xFFF6E0D9);
  static const cinnabarGlyph = Color(0xFFC9483F); // chữ Hán trang trí trên nền primary

  static const jade = Color(0xFF2E6B57); // đúng / hoàn thành
  static const jadeSoft = Color(0xFFDDEDE4);
  static const jadeLine = Color(0xFFBFD9CB);

  static const gold = Color(0xFFE4A93A); // streak / đồng hồ
  static const goldInk = Color(0xFF7A5410);
  static const goldSoft = Color(0xFFFBEBCB);

  static const frostInk = Color(0xFF1E5A7A); // power-up đóng băng
  static const frostSoft = Color(0xFFDCEEF8);
  static const boss = Color(0xFF4A148C);
  static const sky = Color(0xFFBFE3F5); // nền cảnh game
}

/// Kiểu chữ: Noto Serif SC cho chữ Hán, Lora cho tiêu đề/số liệu, Be Vietnam Pro cho nội dung.
class AppText {
  static TextStyle hanzi(double size,
          {Color color = AppColors.ink, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.notoSerifSc(fontSize: size, fontWeight: weight, color: color, height: 1.2);

  static TextStyle display(double size, {Color color = AppColors.ink}) =>
      GoogleFonts.lora(fontSize: size, fontWeight: FontWeight.w700, color: color, height: 1.2);

  static const overline = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.inkSoft,
  );
}

/// Theme chung. Font tải+cache runtime qua google_fonts; offline lần đầu sẽ fallback font hệ thống.
class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.cinnabar).copyWith(
      primary: AppColors.cinnabar,
      onPrimary: AppColors.card,
      primaryContainer: AppColors.cinnabarSoft,
      onPrimaryContainer: AppColors.cinnabarDeep,
      secondary: AppColors.jade,
      onSecondary: AppColors.card,
      secondaryContainer: AppColors.jadeSoft,
      onSecondaryContainer: AppColors.jade,
      tertiary: AppColors.goldInk,
      tertiaryContainer: AppColors.goldSoft,
      onTertiaryContainer: AppColors.goldInk,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkSoft,
      surfaceContainerLowest: AppColors.card,
      surfaceContainerLow: AppColors.card,
      surfaceContainer: AppColors.card,
      surfaceContainerHigh: AppColors.card,
      surfaceContainerHighest: AppColors.track,
      outline: AppColors.line,
      outlineVariant: AppColors.track,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
    );
    // Chữ Hán lẫn trong văn bản thường -> rơi về Noto Serif SC.
    final hanziFallback = [GoogleFonts.notoSerifSc().fontFamily!];
    final text = GoogleFonts.beVietnamProTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
      fontFamilyFallback: hanziFallback,
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.display(24),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cinnabar,
          foregroundColor: AppColors.card,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 44),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.line, width: 1.5),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cinnabarDeep,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.line)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.cinnabarSoft : AppColors.card,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.cinnabarDeep : AppColors.inkSoft,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.card),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.cinnabar : AppColors.disabled,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.cinnabarSoft,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? AppColors.cinnabar : AppColors.inkSoft,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? AppColors.cinnabar : AppColors.inkSoft,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.cinnabar,
        linearTrackColor: AppColors.track,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.track, space: 1, thickness: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.inkSoft,
        subtitleTextStyle: TextStyle(fontSize: 12, color: AppColors.inkSoft),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
