class Notification {
  final String id;
  final String userId;
  final String message;
  final bool readStatus;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.message,
    required this.readStatus,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      message: json['message'] ?? '',
      readStatus: json['read_status'] == true || json['read_status'] == 1,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'message': message,
      'read_status': readStatus ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
