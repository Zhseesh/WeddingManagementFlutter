import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  final Color ink;
  final Color muted;
  final Color line;
  final Color surface;
  final Color background;
  final Color softPrimary;
  final Color softBg;
  final Color softSuccess;
  final Color shadow;

  const AppPalette({
    required this.ink,
    required this.muted,
    required this.line,
    required this.surface,
    required this.background,
    required this.softPrimary,
    required this.softBg,
    required this.softSuccess,
    required this.shadow,
  });

  static const AppPalette light = AppPalette(
    ink: Color(0xFF17183D),
    muted: Color(0xFF77788E),
    line: Color(0xFFEBE9F5),
    surface: Colors.white,
    background: Color(0xFFF7F6FC),
    softPrimary: Color(0xFFF0EDFF),
    softBg: Color(0xFFF7F6FC),
    softSuccess: Color(0xFFE3F8EF),
    shadow: Color(0x1430206B),
  );

  static const AppPalette dark = AppPalette(
    ink: Color(0xFFEAEAF2),
    muted: Color(0xFF9FA0B5),
    line: Color(0xFF2D2D44),
    surface: Color(0xFF1A1A2E),
    background: Color(0xFF0F0F1E),
    softPrimary: Color(0xFF2F2A52),
    softBg: Color(0xFF181828),
    softSuccess: Color(0xFF143628),
    shadow: Color(0x66000000),
  );
}

class AppTheme {
  // Warna semantik (tetap statis)
  static const Color success = Color(0xFF18B77A);
  static const Color warning = Color(0xFFF4A340);
  static const Color error = Color(0xFFED5570);
  static const Color tertiary = Color(0xFF3978ED);
  static const Color secondary = Color(0xFF8B5CF6);
  
  // Fallback primary (jika ada yang masih memanggil AppTheme.primary)
  static const Color primary = Color(0xFF6546E8);

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
  }

  static ThemeData lightTheme(Color seedColor) {
    const p = AppPalette.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: p.surface,
      onSurface: p.ink,
      surfaceContainerHighest: p.line,
      outline: p.line,
      outlineVariant: p.line,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      textTheme: GoogleFonts.interTextTheme(),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.line),
        ),
        color: p.surface,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        titleTextStyle: GoogleFonts.inter(color: p.ink, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle: GoogleFonts.inter(color: p.ink, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(color: p.ink, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: p.ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
        labelStyle: TextStyle(color: p.muted),
        hintStyle: TextStyle(color: p.muted),
      ),
    );
  }

  static ThemeData darkTheme(Color seedColor) {
    const p = AppPalette.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: p.surface,
      onSurface: p.ink,
      surfaceContainerHighest: p.line,
      outline: p.line,
      outlineVariant: p.line,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.line),
        ),
        color: p.surface,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        titleTextStyle: GoogleFonts.inter(color: p.ink, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle: GoogleFonts.inter(color: p.ink, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(color: p.ink, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: p.ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
        labelStyle: TextStyle(color: p.muted),
        hintStyle: TextStyle(color: p.muted),
      ),
    );
  }
}