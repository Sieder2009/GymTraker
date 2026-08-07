import 'package:flutter/material.dart';

import '../services/storage_service.dart';

const String _kAccentKey = 'ironpeak:appearance:accent';
const String _kSecondaryKey = 'ironpeak:appearance:secondary';

/// Custom primary (accent) / secondary color overrides, persisted as ARGB
/// ints. Null means "use the theme's default for the current light/dark
/// mode" — [AppTheme] falls back to [AppColors.light]/[AppColors.dark]'s
/// own accent/secondary whenever these are unset.
class AppearanceProvider extends ChangeNotifier {
  AppearanceProvider(this._storage)
      : _accent = _readColor(_storage, _kAccentKey),
        _secondary = _readColor(_storage, _kSecondaryKey);

  final StorageService _storage;
  Color? _accent;
  Color? _secondary;

  Color? get accent => _accent;
  Color? get secondary => _secondary;

  static Color? _readColor(StorageService storage, String key) {
    final raw = storage.readString(key);
    if (raw == null || raw.isEmpty) return null;
    final value = int.tryParse(raw);
    return value == null ? null : Color(value);
  }

  void setAccent(Color color) {
    _accent = color;
    _storage.writeString(_kAccentKey, color.toARGB32().toString());
    notifyListeners();
  }

  void setSecondary(Color color) {
    _secondary = color;
    _storage.writeString(_kSecondaryKey, color.toARGB32().toString());
    notifyListeners();
  }

  void reset() {
    _accent = null;
    _secondary = null;
    _storage.writeString(_kAccentKey, '');
    _storage.writeString(_kSecondaryKey, '');
    notifyListeners();
  }
}
