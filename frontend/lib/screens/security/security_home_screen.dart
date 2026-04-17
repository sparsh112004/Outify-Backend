import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/outing_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/requests_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/request_list_shimmer.dart';

class SecurityHomeScreen extends ConsumerStatefulWidget {
  const SecurityHomeScreen({super.key});

  @override
  ConsumerState<SecurityHomeScreen> createState() => _SecurityHomeScreenState();
}

class _SecurityHomeScreenState extends ConsumerState<SecurityHomeScreen> {
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
        ref.read(requestsProvider.notifier).fetchSecurityToday();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final req = ref.watch(requestsProvider);

    final outCount = req.items.where((r) => r.overallStatus == 'out').length;
    final approvedToday = req.items.where((r) => r.overallStatus == 'approved').length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(requestsProvider.notifier).fetchSecurityToday(),
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
                      colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Icon(Icons.security, size: 200, color: Colors.white.withOpacity(0.05)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Security Console',
                              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
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
                  onPressed: () => Navigator.of(context).pushNamed('/security/scan'),
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
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
                    Row(
                      children: [
                        Expanded(
                          child: _SecurityStatCard(
                            label: 'Approved Today',
                            value: approvedToday.toString(),
                            icon: Icons.assignment_turned_in_rounded,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SecurityStatCard(
                            label: 'Students Out',
                            value: outCount.toString(),
                            icon: Icons.exit_to_app_rounded,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Today's Activities",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (req.isLoading && req.items.isEmpty)
                      const RequestListShimmer()
                    else if (req.error != null)
                      _ErrorView(error: req.error!, onRetry: () => ref.read(requestsProvider.notifier).fetchSecurityToday())
                    else if (req.items.isEmpty)
                      const _EmptySecurityView()
                    else
                      ...req.items.map((r) => _SecurityRequestTile(request: r)),
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

class _SecurityStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SecurityStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SecurityRequestTile extends StatelessWidget {
  final OutingRequest request;
  const _SecurityRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm a').format(request.departureDatetime);
    final isOut = request.overallStatus == 'out';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isOut ? Colors.orange : Colors.blue).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOut ? Icons.login_rounded : Icons.logout_rounded, // Swap icons: login is for returning, logout is for leaving
            color: isOut ? Colors.orange : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(request.studentName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            if (isOut)
              const Text('OUT OF CAMPUS', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))
            else
              const Text('WAITING TO EXIT', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Reason: ${request.reason}', style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Scheduled: $time', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).pushNamed('/security/verify/${request.id}'),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == 'out' ? Colors.deepPurple : Colors.blue;
    if (status == 'completed') color = Colors.green;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptySecurityView extends StatelessWidget {
  const _EmptySecurityView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('No activities for today.'),
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

