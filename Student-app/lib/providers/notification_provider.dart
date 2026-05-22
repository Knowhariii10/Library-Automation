import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

class NotificationProvider with ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DatabaseHelper.instance.getNotifications();
      _notifications = data;
    } catch (e) {
      print('DEBUG: NotificationProvider.loadNotifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearNotifications() {
    _notifications = [];
    notifyListeners();
  }
}
