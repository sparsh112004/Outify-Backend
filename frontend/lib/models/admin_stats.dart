class AdminDashboardStats {
  final int totalUsers;
  final int totalStudents;
  final int studentsOut;
  final int pendingApprovals;
  final int todayRequests;
  final int lateReturnsToday;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalStudents,
    required this.studentsOut,
    required this.pendingApprovals,
    required this.todayRequests,
    required this.lateReturnsToday,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalUsers: json['total_users'] as int? ?? 0,
      totalStudents: json['total_students'] as int? ?? 0,
      studentsOut: json['students_out'] as int? ?? 0,
      pendingApprovals: json['pending_approvals'] as int? ?? 0,
      todayRequests: json['today_requests'] as int? ?? 0,
      lateReturnsToday: json['late_returns_today'] as int? ?? 0,
    );
  }

  factory AdminDashboardStats.empty() {
    return const AdminDashboardStats(
      totalUsers: 0,
      totalStudents: 0,
      studentsOut: 0,
      pendingApprovals: 0,
      todayRequests: 0,
      lateReturnsToday: 0,
    );
  }
}
