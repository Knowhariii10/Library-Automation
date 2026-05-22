import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityProvider with ChangeNotifier {
  ConnectivityStatus _status = ConnectivityStatus.online;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityStatus get status => _status;

  ConnectivityProvider() {
    _checkInitialConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateStatus(results);
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    print('DEBUG: Connectivity changed to: $results');
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      _status = ConnectivityStatus.offline;
    } else {
      _status = ConnectivityStatus.online;
    }
    print('DEBUG: ConnectivityProvider status: $_status');
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
