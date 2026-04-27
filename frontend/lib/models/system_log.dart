class SystemLog {
  final int id;
  final String? userName;
  final String? userEmail;
  final String action;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  const SystemLog({
    required this.id,
    this.userName,
    this.userEmail,
    required this.action,
    this.details,
    required this.createdAt,
  });

  factory SystemLog.fromJson(Map<String, dynamic> json) {
    return SystemLog(
      id: json['id'] as int? ?? 0,
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      action: (json['action'] ?? '') as String,
      details: json['details'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }
}
