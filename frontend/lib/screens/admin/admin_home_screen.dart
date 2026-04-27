import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin_stats.dart';
import '../../models/system_log.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/logs_provider.dart';
import '../../utils/theme.dart';
import 'admin_edit_user_screen.dart';
import 'admin_stat_detail_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180, // Increased height to accommodate TabBar space
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Administration', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      Text('Master Control Console', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                      const SizedBox(height: 52), // Reservation for TabBar
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(onPressed: () => ref.read(authProvider.notifier).logout(), icon: const Icon(Icons.logout, color: Colors.white)),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: false, // Changed to false for 4 tabs
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 4,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Users'),
                Tab(text: 'Units'),
                Tab(text: 'Logs'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _OverviewTab(),
            _UserList(role: null),
            _DepartmentsList(),
            _LogsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/admin/create_user'),
        icon: const Icon(Icons.add_moderator_rounded),
        label: const Text('Add Personnel'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _UserList extends ConsumerStatefulWidget {
  final String? role;
  const _UserList({this.role});

  @override
  ConsumerState<_UserList> createState() => _UserListState();
}

class _UserListState extends ConsumerState<_UserList> {
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).fetchUsers(role: _selectedRole);
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              _buildRoleChip(null, 'All'),
              const SizedBox(width: 8),
              _buildRoleChip('student', 'Students'),
              const SizedBox(width: 8),
              _buildRoleChip('faculty', 'Faculty'),
              const SizedBox(width: 8),
              _buildRoleChip('warden', 'Wardens'),
              const SizedBox(width: 8),
              _buildRoleChip('security', 'Security'),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.read(adminProvider.notifier).fetchUsers(role: _selectedRole),
            child: admin.isLoading && admin.users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: admin.users.length,
                    itemBuilder: (context, index) {
                      final u = admin.users[index];
                      return _AdminUserTile(user: u);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String? role, String label) {
    final isSelected = _selectedRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedRole = role);
          ref.read(adminProvider.notifier).fetchUsers(role: role);
        }
      },
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _AdminUserTile extends StatelessWidget {
  final u; // Placeholder for AppUser
  const _AdminUserTile({required this.user}) : u = user;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: const TextStyle(fontSize: 12)),
            if (user.department != null) Text(user.department!, style: TextStyle(fontSize: 12, color: AppTheme.primaryColor.withOpacity(0.7))),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminEditUserScreen(user: user)));
        },
      ),
    );
  }
}

class _DepartmentsList extends ConsumerStatefulWidget {
  const _DepartmentsList();

  @override
  ConsumerState<_DepartmentsList> createState() => _DepartmentsListState();
}

class _DepartmentsListState extends ConsumerState<_DepartmentsList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(departmentProvider.notifier).fetchDepartments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(departmentProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(departmentProvider.notifier).fetchDepartments(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Academic Units', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  FilledButton.icon(
                    onPressed: () => _showAddDialog(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('New Unit'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 16)),
                  ),
                ],
              ),
            ),
          ),
          if (state.isLoading && state.departments.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (state.error != null)
            SliverToBoxAdapter(child: Center(child: Text(state.error!)))
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final d = state.departments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.premiumShadow,
                      ),
                      child: ListTile(
                        title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showEditDialog(context, ref, d.id, d.name)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _showDeleteConfirm(context, ref, d.id)),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: state.departments.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Department'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Department Name'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(departmentProvider.notifier).createDepartment(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, int id, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Department'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Department Name'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(departmentProvider.notifier).updateDepartment(id, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department?'),
        content: const Text('This will remove the department. Users assigned to this department will have it set to null. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(departmentProvider.notifier).deleteDepartment(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab();

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminDashboardProvider.notifier).fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(adminDashboardProvider.notifier).fetchStats(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('System Health', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                label: 'Total Students',
                value: state.stats.totalStudents.toString(),
                icon: Icons.school_outlined,
                color: Colors.indigo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminStatDetailScreen(type: 'total_students'),
                  ),
                ),
              ),
              _StatCard(
                label: 'Students off-campus',
                value: state.stats.studentsOut.toString(),
                icon: Icons.exit_to_app_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminStatDetailScreen(type: 'off_campus'),
                  ),
                ),
              ),
              _StatCard(
                label: 'Total Users',
                value: state.stats.totalUsers.toString(),
                icon: Icons.people_outline,
                color: Colors.blue,
              ),
              _StatCard(
                label: 'Pending Approvals',
                value: state.stats.pendingApprovals.toString(),
                icon: Icons.hourglass_empty_rounded,
                color: Colors.red,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminStatDetailScreen(type: 'pending'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _StatCard(
            label: "Requests Created Today",
            value: state.stats.todayRequests.toString(),
            icon: Icons.today_rounded,
            color: Colors.green,
            isWide: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminStatDetailScreen(type: 'today'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StatCard(
            label: "Late Returns Today",
            value: state.stats.lateReturnsToday.toString(),
            icon: Icons.access_time_filled_rounded,
            color: Colors.redAccent,
            isWide: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminStatDetailScreen(type: 'late'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isWide;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isWide = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.premiumShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogsTab extends ConsumerStatefulWidget {
  const _LogsTab();

  @override
  ConsumerState<_LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends ConsumerState<_LogsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(logsProvider.notifier).fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(logsProvider.notifier).fetchLogs(),
      child: state.isLoading && state.logs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final log = state.logs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.05)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          _getLogIcon(log.action),
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  log.userName ?? 'System',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  _formatTime(log.createdAt),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatAction(log.action),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            if (log.details != null && log.details!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                log.details.toString(),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  IconData _getLogIcon(String action) {
    if (action.contains('approved')) return Icons.check_circle_outline;
    if (action.contains('denied')) return Icons.cancel_outlined;
    if (action.contains('login')) return Icons.login_rounded;
    if (action.contains('scan') || action.contains('verify')) return Icons.qr_code_scanner_rounded;
    return Icons.info_outline_rounded;
  }

  String _formatAction(String action) {
    return action.replaceAll('_', ' ').split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s).join(' ');
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}

