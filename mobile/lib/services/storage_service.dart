import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences], mirroring the original
/// `persisted.js`: load once at startup (SharedPreferences itself already
/// caches all keys in memory after [create]), write-through JSON on every
/// mutation, fail-soft (never throw) if storage access fails.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  String? readString(String key) {
    try {
      return _prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (_) {
      // fail-soft: in-memory state (held by the calling ChangeNotifier)
      // still updates even if persistence itself didn't succeed.
    }
  }

  T? readJson<T>(String key, T Function(dynamic decoded) fromJson) {
    final raw = readString(key);
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String key, Object? Function() toJson) {
    return writeString(key, jsonEncode(toJson()));
  }
}
