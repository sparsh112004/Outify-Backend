import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/outing_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/requests_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/request_list_shimmer.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/live_countdown.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        ref.read(requestsProvider.notifier).fetchStudentRequests();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final req = ref.watch(requestsProvider);

    final pendingCount = req.items.where((r) => r.overallStatus.contains('pending')).length;
    final approvedCount = req.items.where((r) => r.overallStatus == 'approved').length;
    final activeOuting = req.items.where((r) => r.overallStatus == 'out').firstOrNull;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(requestsProvider.notifier).fetchStudentRequests(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor ?? Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: CircleAvatar(
                          radius: 100,
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${auth.user?.name.split(' ')[0] ?? ''} 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Ready for your next adventure?',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pushNamed('/student/profile'),
                  icon: const Icon(Icons.person, color: Colors.white),
                ),
                IconButton(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  icon: const Icon(Icons.logout, color: Colors.white),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activeOuting != null) ...[
                      LiveCountdown(
                        targetTime: activeOuting.expectedReturnDatetime,
                        label: 'Active Outing Return Deadline',
                      ),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Pending',
                            value: pendingCount.toString(),
                            icon: Icons.timer_outlined,
                            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            label: 'Approved',
                            value: approvedCount.toString(),
                            icon: Icons.verified_outlined,
                            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Requests',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {}, // Action for "See All" if implemented
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (req.isLoading && req.items.isEmpty)
                      const RequestListShimmer()
                    else if (req.error != null)
                      _ErrorView(error: req.error!, onRetry: () => ref.read(requestsProvider.notifier).fetchStudentRequests())
                    else if (req.items.isEmpty)
                      const _EmptyView()
                    else
                      ...req.items.take(10).map((r) => _PremiumRequestTile(request: r)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/student/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Request Outing'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({required this.label, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: gradient.last.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PremiumRequestTile extends StatelessWidget {
  final OutingRequest request;
  const _PremiumRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, MMM dd').format(request.departureDatetime);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(request.reason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            _StatusChip(status: request.overallStatus),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chevron_right_rounded, color: Theme.of(context).primaryColor),
        ),
        onTap: () => Navigator.of(context).pushNamed('/requests/${request.id}'),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.auto_awesome_motion_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No requests found', style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('When you create outing requests, they will appear here.', style: TextStyle(color: Colors.grey[400], fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      case 'out':
        color = Colors.deepPurple;
        break;
      default:
        color = status.contains('denied') ? Colors.red : Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
