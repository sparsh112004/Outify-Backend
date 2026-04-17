import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../utils/theme.dart';
import 'admin_edit_user_screen.dart';

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
    _tabController = TabController(length: 6, vsync: this);
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
              isScrollable: true,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 4,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'All Users'),
                Tab(text: 'Students'),
                Tab(text: 'Faculty'),
                Tab(text: 'Wardens'),
                Tab(text: 'Security'),
                Tab(text: 'Departments'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _UserList(role: null),
            _UserList(role: 'student'),
            _UserList(role: 'faculty'),
            _UserList(role: 'warden'),
            _UserList(role: 'security'),
            _DepartmentsList(),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).fetchUsers(role: widget.role);
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(adminProvider.notifier).fetchUsers(role: widget.role),
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

