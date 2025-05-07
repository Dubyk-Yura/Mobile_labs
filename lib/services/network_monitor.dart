import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkMonitor {
  static final Connectivity _connectivity = Connectivity();

  static Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Stream<ConnectivityResult> get onConnectionChange =>
      _connectivity.onConnectivityChanged;
}
