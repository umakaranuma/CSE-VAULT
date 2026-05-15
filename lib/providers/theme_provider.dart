import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _key = 'isDark';

  bool _isDark = true;
  bool get isDark => _isDark;

  ThemeProvider() {
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = Hive.box(_boxName);
    _isDark = box.get(_key, defaultValue: true);
    notifyListeners();
  }

  void toggle() {
    _isDark = !_isDark;
    Hive.box(_boxName).put(_key, _isDark);
    notifyListeners();
  }

  void setDark() {
    _isDark = true;
    Hive.box(_boxName).put(_key, true);
    notifyListeners();
  }

  void setLight() {
    _isDark = false;
    Hive.box(_boxName).put(_key, false);
    notifyListeners();
  }
}
