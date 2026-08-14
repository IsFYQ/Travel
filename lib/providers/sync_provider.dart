import 'package:flutter/foundation.dart';

/// P1-3.4：同步状态占位（板块4 SyncEngine 接入前）
class SyncProvider extends ChangeNotifier {
  bool _syncing = false;
  String? _lastError;

  bool get syncing => _syncing;
  String? get lastError => _lastError;

  void setSyncing(bool value) {
    _syncing = value;
    notifyListeners();
  }

  void setError(String? error) {
    _lastError = error;
    notifyListeners();
  }
}
