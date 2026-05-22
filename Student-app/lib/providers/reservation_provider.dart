import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

class ReservationProvider with ChangeNotifier {
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get reservations => _reservations;
  bool get isLoading => _isLoading;

  Future<void> loadReservations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DatabaseHelper.instance.getReservations();
      _reservations = data;
    } catch (e) {
      print('DEBUG: ReservationProvider.loadReservations error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearReservations() {
    _reservations = [];
    notifyListeners();
  }
}
