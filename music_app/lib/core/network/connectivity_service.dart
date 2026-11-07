import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Theo dõi trạng thái kết nối mạng (WIFI/MOBILE/NONE).
/// Dùng để quyết định gọi RESTful API hay ghi vào Pending Sync Queue.
class ConnectivityService extends ChangeNotifier {
  final Connectivity _conn = Connectivity();
  bool isOnline = true;

  ConnectivityService() {
    _conn.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      isOnline = !results.contains(ConnectivityResult.none);
      notifyListeners();
    });
    refresh();
  }

  Future<void> refresh() async {
    try {
      final List<ConnectivityResult> results = await _conn.checkConnectivity();
      isOnline = !results.contains(ConnectivityResult.none);
      notifyListeners();
    } catch (_) {}
  }
}
