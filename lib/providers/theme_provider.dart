import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({
    ThemeService? service,
  }) : _service = service ?? ThemeService();

  final ThemeService _service;

  bool _isDarkMode = false;
  bool _isLoading = true;

  bool get isDarkMode => _isDarkMode;

  bool get isLoading => _isLoading;

  ThemeMode get themeMode {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> loadTheme() async {
    try {
      _isDarkMode = await _service.getDarkMode();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    notifyListeners();

    await _service.saveDarkMode(enabled);
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }
}