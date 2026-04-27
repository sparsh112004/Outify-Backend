import '../utils/constants.dart';

class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? collegeId;
  final String? department;
  final String? gender;
  final String? roomNumber;
  final String? fcmToken;
  final String? profilePicUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.collegeId,
    this.department,
    this.gender,
    this.roomNumber,
    this.fcmToken,
    this.profilePicUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      collegeId: json['college_id'] as String?,
      department: json['department'] as String?,
      gender: json['gender'] as String?,
      roomNumber: json['room_number'] as String?,
      fcmToken: json['fcm_token'] as String?,
      profilePicUrl: json['profile_pic'] != null
          ? (json['profile_pic'].toString().startsWith('http')
              ? json['profile_pic'].toString()
              : '${AppConstants.apiBaseUrl.split('/api/')[0]}${json['profile_pic']}')
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'college_id': collegeId,
      'department': department,
      'gender': gender,
      'room_number': roomNumber,
      'fcm_token': fcmToken,
      'profile_pic': profilePicUrl,
    };
  }
}
