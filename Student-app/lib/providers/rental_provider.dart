import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

class RentalProvider with ChangeNotifier {
  List<Map<String, dynamic>> _rentals = [];
  Map<String, Map<String, dynamic>> _bookDetails = {};
  bool _isLoading = false;

  List<Map<String, dynamic>> get rentals => _rentals;
  Map<String, Map<String, dynamic>> get bookDetails => _bookDetails;
  bool get isLoading => _isLoading;

  Future<void> loadRentals() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DatabaseHelper.instance.getRentals();
      final Map<String, Map<String, dynamic>> details = {};

      for (var rental in data) {
        final bookId = rental['book_id'];
        if (bookId != null) {
          final book = await DatabaseHelper.instance.getBookById(bookId);
          if (book != null) {
            details[bookId] = book;
          }
        }
      }

      _rentals = data;
      _bookDetails = details;
    } catch (e) {
      print('DEBUG: RentalProvider.loadRentals error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearRentals() {
    _rentals = [];
    _bookDetails = {};
    notifyListeners();
  }
}
