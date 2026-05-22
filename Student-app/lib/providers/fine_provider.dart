import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

class FineProvider with ChangeNotifier {
  List<Map<String, dynamic>> _fines = [];
  bool _isLoading = false;
  double _totalPaid = 0;
  double _totalPending = 0;

  List<Map<String, dynamic>> get fines => _fines;
  bool get isLoading => _isLoading;
  double get totalPaid => _totalPaid;
  double get totalPending => _totalPending;

  Future<void> loadFines() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DatabaseHelper.instance.getFines();
      _fines = data;

      double paid = 0;
      double pending = 0;

      for (var fine in data) {
        final amount = (fine['amount'] ?? 0.0).toDouble();
        final isPaid = fine['status'] == 'PAID';
        if (isPaid) {
          paid += amount;
        } else {
          pending += amount;
        }
      }

      _totalPaid = paid;
      _totalPending = pending;
    } catch (e) {
      print('DEBUG: FineProvider.loadFines error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearFines() {
    _fines = [];
    _totalPaid = 0;
    _totalPending = 0;
    notifyListeners();
  }
}
