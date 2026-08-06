import 'package:flutter/widgets.dart';

import '../services/storage_service.dart';

const String _kThemeKey = 'ironpeak:theme';

/// 'light' | 'dark'. Defaults to the OS preference on first launch only —
/// after that, whatever the user picked via [toggle] persists.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._storage) : _mode = _initial(_storage);

  final StorageService _storage;
  String _mode;

  String get mode => _mode;
  bool get isDark => _mode == 'dark';

  static String _initial(StorageService storage) {
    final saved = storage.readString(_kThemeKey);
    if (saved == 'light' || saved == 'dark') return saved!;
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark ? 'dark' : 'light';
  }

  void toggle() {
    _mode = _mode == 'dark' ? 'light' : 'dark';
    _storage.writeString(_kThemeKey, _mode);
    notifyListeners();
  }
}
