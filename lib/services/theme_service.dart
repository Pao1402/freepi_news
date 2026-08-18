import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'dark_mode_enabled';

  Future<bool> getDarkMode() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool(_themeKey) ?? false;
  }

  Future<void> saveDarkMode(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_themeKey, enabled);
  }
}