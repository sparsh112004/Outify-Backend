import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/outing_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/requests_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/request_list_shimmer.dart';

class FacultyHomeScreen extends ConsumerStatefulWidget {
  const FacultyHomeScreen({super.key});

  @override
  ConsumerState<FacultyHomeScreen> createState() => _FacultyHomeScreenState();
}

class _FacultyHomeScreenState extends ConsumerState<FacultyHomeScreen> {
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
        ref.read(requestsProvider.notifier).fetchFacultyPending();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final req = ref.watch(requestsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(requestsProvider.notifier).fetchFacultyPending(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Icon(Icons.school, size: 200, color: Colors.white.withOpacity(0.05)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Faculty Portal',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Logged in as ${auth.user?.name ?? ''}',
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                  onPressed: () => Navigator.of(context).pushNamed('/profile'),
                  icon: const Icon(Icons.account_circle, color: Colors.white),
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
                    _FacultyStatCard(
                      label: 'Pending Approvals',
                      value: req.items.length.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Approval Queue',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (req.isLoading && req.items.isEmpty)
                      const RequestListShimmer()
                    else if (req.error != null)
                      _ErrorView(error: req.error!, onRetry: () => ref.read(requestsProvider.notifier).fetchFacultyPending())
                    else if (req.items.isEmpty)
                      const _EmptyFacultyView()
                    else
                      ...req.items.map((r) => _FacultyRequestTile(request: r)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacultyStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _FacultyStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(color: color.withOpacity(0.7), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FacultyRequestTile extends ConsumerWidget {
  final OutingRequest request;
  const _FacultyRequestTile({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateFormat('MMM dd, hh:mm a').format(request.departureDatetime);
    final reqState = ref.watch(requestsProvider);
    final isAwaitingParent = request.overallStatus == 'pending_parent';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(request.studentName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              if (isAwaitingParent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('AWAITING PARENT', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('ACTION REQUIRED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Reason: ${request.reason}', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              if (isAwaitingParent)
                const Text(
                  'You can approve this once the parent provides permission.',
                  style: TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: reqState.isLoading ? null : () => ref.read(requestsProvider.notifier).facultyDecide(requestId: request.id, decision: 'approved'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: reqState.isLoading ? null : () => ref.read(requestsProvider.notifier).facultyDecide(requestId: request.id, decision: 'rejected'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          onTap: () => Navigator.of(context).pushNamed('/requests/${request.id}'),
        ),
      ),
    );
  }
}

class _EmptyFacultyView extends StatelessWidget {
  const _EmptyFacultyView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('All caught up! No pending requests.'),
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
    return Column(
      children: [
        Text(error, style: const TextStyle(color: Colors.red)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}


