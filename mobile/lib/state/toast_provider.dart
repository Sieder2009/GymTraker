import 'dart:async';

import 'package:flutter/foundation.dart';

/// Mirrors `toast.js`: a new toast cancels any pending auto-hide timer and
/// restarts a fresh ~2100ms auto-hide (debounced), so rapid successive
/// toasts don't flicker.
class ToastProvider extends ChangeNotifier {
  String _message = '';
  bool _visible = false;
  Timer? _hideTimer;

  String get message => _message;
  bool get visible => _visible;

  void show(String message) {
    _hideTimer?.cancel();
    _message = message;
    _visible = true;
    notifyListeners();
    _hideTimer = Timer(const Duration(milliseconds: 2100), () {
      _visible = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}
