import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeColorKey = 'theme_accent_color';
const _defaultColor = Color(0xFF6546E8);

final themeColorProvider = StateNotifierProvider<ThemeColorNotifier, Color>((ref) {
  return ThemeColorNotifier();
});

class ThemeColorNotifier extends StateNotifier<Color> {
  ThemeColorNotifier() : super(_defaultColor) {
    _loadColor();
  }

  Future<void> _loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_kThemeColorKey);
    if (colorValue != null) {
      state = Color(colorValue);
    }
  }

  Future<void> setColor(Color color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeColorKey, color.toARGB32()); // 👈 Fix deprecated
  }
}