import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../models/outing_request.dart';
import '../../providers/admin_provider.dart';
import '../../providers/admin_outings_provider.dart';
import '../../utils/theme.dart';
import 'admin_edit_user_screen.dart';

class AdminStatDetailScreen extends ConsumerStatefulWidget {
  final String type;

  const AdminStatDetailScreen({super.key, required this.type});

  @override
  ConsumerState<AdminStatDetailScreen> createState() => _AdminStatDetailScreenState();
}

class _AdminStatDetailScreenState extends ConsumerState<AdminStatDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    if (widget.type == 'total_students') {
      ref.read(adminProvider.notifier).fetchUsers(role: 'student');
    } else if (widget.type == 'off_campus') {
      ref.read(adminOutingsProvider.notifier).fetchOutings(status: 'out');
    } else if (widget.type == 'pending') {
      ref.read(adminOutingsProvider.notifier).fetchOutings(status: 'pending');
    } else if (widget.type == 'today') {
      ref.read(adminOutingsProvider.notifier).fetchOutings(date: 'today');
    } else if (widget.type == 'late') {
      ref.read(adminOutingsProvider.notifier).fetchOutings(status: 'late');
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case 'total_students':
        return 'Student Directory';
      case 'off_campus':
        return 'Students Off-Campus';
      case 'pending':
        return 'Pending Requests';
      case 'today':
        return "Today's Requests";
      case 'late':
        return 'Late Returns Today';
      default:
        return 'Details';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUserMode = widget.type == 'total_students';
    final adminState = ref.watch(adminProvider);
    final outingState = ref.watch(adminOutingsProvider);

    final bool isLoading = isUserMode ? adminState.isLoading : outingState.isLoading;
    final List items = isUserMode ? adminState.users : outingState.outings;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchData(),
        child: isLoading && items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? const Center(child: Text('No records found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (isUserMode) {
                        return _UserDetailTile(user: item as AppUser);
                      } else {
                        return _OutingDetailCard(outing: item as OutingRequest);
                      }
                    },
                  ),
      ),
    );
  }
}

class _UserDetailTile extends StatelessWidget {
  final AppUser user;
  const _UserDetailTile({required this.user});

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
          child: Text(user.name[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminEditUserScreen(user: user)));
        },
      ),
    );
  }
}

class _OutingDetailCard extends StatelessWidget {
  final OutingRequest outing;
  const _OutingDetailCard({required this.outing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  outing.studentName ?? 'Student',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _StatusBadge(status: outing.overallStatus),
            ],
          ),
          const Divider(height: 24),
          _InfoRow(icon: Icons.place_outlined, label: 'Destination', value: outing.destination ?? 'Not specified'),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.timer_outlined, label: 'Exp. Return', value: _formatDate(outing.expectedReturnDatetime)),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.notes_rounded, label: 'Reason', value: outing.reason),
          if (outing.securityRemarks != null && outing.securityRemarks!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.comment_bank_outlined, label: 'Security Notes', value: outing.securityRemarks!),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'out') color = Colors.orange;
    if (status == 'completed') color = Colors.green;
    if (status.contains('pending')) color = Colors.blue;
    if (status.contains('denied')) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
