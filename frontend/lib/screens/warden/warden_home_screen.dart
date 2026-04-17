import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/outing_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/requests_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/request_list_shimmer.dart';

class WardenHomeScreen extends ConsumerStatefulWidget {
  const WardenHomeScreen({super.key});

  @override
  ConsumerState<WardenHomeScreen> createState() => _WardenHomeScreenState();
}

class _WardenHomeScreenState extends ConsumerState<WardenHomeScreen> {
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
        ref.read(requestsProvider.notifier).fetchWardenPending();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final req = ref.watch(requestsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(requestsProvider.notifier).fetchWardenPending(),
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
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Icon(Icons.meeting_room, size: 200, color: Colors.white.withOpacity(0.05)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warden Dashboard',
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
                    _WardenStatCard(
                      label: 'Action Required',
                      value: req.items.length.toString(),
                      icon: Icons.notifications_active_outlined,
                      color: const Color(0xFF8B5CF6),
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
                      _ErrorView(error: req.error!, onRetry: () => ref.read(requestsProvider.notifier).fetchWardenPending())
                    else if (req.items.isEmpty)
                      const _EmptyWardenView()
                    else
                      ...req.items.map((r) => _WardenRequestTile(request: r)),
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

class _WardenStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _WardenStatCard({required this.label, required this.value, required this.icon, required this.color});

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

class _WardenRequestTile extends StatelessWidget {
  final OutingRequest request;
  const _WardenRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM dd, hh:mm a').format(request.departureDatetime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(request.studentName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_right_rounded),
        ),
        onTap: () => Navigator.of(context).pushNamed('/warden/decide/${request.id}'),
      ),
    );
  }
}

class _EmptyWardenView extends StatelessWidget {
  const _EmptyWardenView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('No pending requests found.'),
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


