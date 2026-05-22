import 'dart:convert';

class Transaction {
  final String id;
  final String transactionId;
  final String userId;
  final double amount;
  final DateTime date;
  final String type;
  final String message;
  final String status;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> qrPayload;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? returnedAt;
  final double fineAmount;
  final bool finePaid;

  Transaction({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.amount,
    required this.date,
    required this.type,
    this.message = '',
    required this.status,
    required this.items,
    required this.qrPayload,
    required this.createdAt,
    this.dueDate,
    this.returnedAt,
    this.fineAmount = 0.0,
    this.finePaid = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    dynamic itemsRaw = json['items'];
    List<Map<String, dynamic>> itemsList = [];
    if (itemsRaw is String && itemsRaw.isNotEmpty) {
      try {
        itemsList = List<Map<String, dynamic>>.from(jsonDecode(itemsRaw));
      } catch (e) {
        print('Error decoding items: $e');
      }
    } else if (itemsRaw is List) {
      itemsList = List<Map<String, dynamic>>.from(itemsRaw);
    }

    dynamic qrRaw = json['qr_payload'];
    Map<String, dynamic> qrMap = {};
    if (qrRaw is String && qrRaw.isNotEmpty) {
      try {
        qrMap = Map<String, dynamic>.from(jsonDecode(qrRaw));
      } catch (e) {
        print('Error decoding qr_payload: $e');
      }
    } else if (qrRaw is Map) {
      qrMap = Map<String, dynamic>.from(qrRaw);
    }

    return Transaction(
      id: json['id'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'PENDING',
      items: itemsList,
      qrPayload: qrMap,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? ''),
      returnedAt: DateTime.tryParse(json['returned_at']?.toString() ?? ''),
      fineAmount: (json['fine_amount'] ?? 0.0).toDouble(),
      finePaid: json['fine_paid'] == true || json['fine_paid'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'user_id': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'message': message,
      'status': status,
      'items': jsonEncode(items),
      'qr_payload': jsonEncode(qrPayload),
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'fine_amount': fineAmount,
      'fine_paid': finePaid ? 1 : 0,
    };
  }
}
