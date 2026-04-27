import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/outing_request.dart';
import '../../providers/requests_provider.dart';
import '../../utils/theme.dart';

class SecurityVerifyScreen extends ConsumerStatefulWidget {
  final int requestId;
  const SecurityVerifyScreen({super.key, required this.requestId});

  @override
  ConsumerState<SecurityVerifyScreen> createState() => _SecurityVerifyScreenState();
}

class _SecurityVerifyScreenState extends ConsumerState<SecurityVerifyScreen> {
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(requestsProvider.notifier).fetchRequestDetails(widget.requestId);
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  bool _isLate(DateTime? expectedReturn) {
    if (expectedReturn == null) return false;
    return DateTime.now().isAfter(expectedReturn);
  }

  String _getLatenessText(DateTime expectedReturn) {
    final diff = DateTime.now().difference(expectedReturn);
    if (diff.isNegative) return '';
    
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m overdue';
    } else {
      return '${diff.inMinutes}m overdue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestsProvider);
    final request = state.currentRequest;
    final isOut = request?.overallStatus == 'out';
    final isApproved = request?.overallStatus == 'approved';
    final bool late = isOut && request != null && _isLate(request.expectedReturnDatetime);

    return Scaffold(
      appBar: AppBar(title: const Text('Gate Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.isLoading && request == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (request == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 24),
                    Text(
                      state.error != null ? 'Error: ${state.error}' : 'No active request found or could not load details.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () => ref.read(requestsProvider.notifier).fetchRequestDetails(widget.requestId),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Refreshing'),
                    ),
                  ],
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: (isOut ? Colors.orange : Colors.blue).withOpacity(0.1),
                      child: Icon(
                        isOut ? Icons.login_rounded : Icons.logout_rounded,
                        color: isOut ? Colors.orange : Colors.blue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(request.studentName ?? 'Student', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Reason: ${request.reason}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const Divider(height: 32),
                    _InfoRow(label: 'Status', value: request.overallStatus.toUpperCase().replaceAll('_', ' ')),
                    _InfoRow(label: 'Exp. Return', value: DateFormat('MMM d, hh:mm a').format(request.expectedReturnDatetime)),
                    _InfoRow(label: 'Destination', value: request.destination ?? 'Not specified'),
                  ],
                ),
              ),
              if (late) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LATE RETURN WARNING',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              _getLatenessText(request.expectedReturnDatetime),
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Remarks Field (Focus on lateness reason)
              TextField(
                controller: _remarksController,
                decoration: InputDecoration(
                  labelText: late ? 'Reason for Lateness' : 'Security Remarks (Optional)',
                  hintText: late ? 'Ask student for reason of delay...' : 'Enter any notes...',
                  prefixIcon: Icon(late ? Icons.edit_note_rounded : Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: late ? Colors.red.withOpacity(0.05) : null,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              if (isApproved)
                FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          await ref.read(requestsProvider.notifier).securityVerify(
                                requestId: widget.requestId,
                                action: 'exit',
                                remarks: _remarksController.text,
                              );
                          if (mounted) Navigator.pop(context);
                        },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('VERIFY EXIT (Student Leaving)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              if (isOut)
                FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          await ref.read(requestsProvider.notifier).securityVerify(
                                requestId: widget.requestId,
                                action: 'entry',
                                remarks: _remarksController.text,
                              );
                          if (mounted) Navigator.pop(context);
                        },
                  icon: const Icon(Icons.home_outlined),
                  label: Text(late ? 'VERIFY LATE ENTRY' : 'VERIFY ENTRY (Student Returned)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: late ? Colors.deepOrange : Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              if (!isApproved && !isOut)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    'This request is not in a verifiable state (either not approved yet or already completed).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
