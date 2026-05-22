import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';
import '../models/transaction.dart' as tx_model;

class TransactionProvider with ChangeNotifier {
  List<tx_model.Transaction> _transactions = [];
  bool _isLoading = false;

  List<tx_model.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final txData = await DatabaseHelper.instance.getTransactions();
      _transactions = txData
          .map((e) => tx_model.Transaction.fromJson(e))
          .toList();
    } catch (e) {
      print('DEBUG: TransactionProvider.loadTransactions error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearTransactions() {
    _transactions = [];
    notifyListeners();
  }
}
