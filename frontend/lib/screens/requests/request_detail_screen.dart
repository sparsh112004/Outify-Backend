import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../widgets/status_timeline.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final int requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.dio.get('/requests/${widget.requestId}');
      setState(() {
        _data = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cancelRequest() async {
    setState(() => _loading = true);
    try {
      await ApiService.dio.post('/requests/${widget.requestId}/cancel');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          if (!_loading && _error == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(_error!),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildTimeline(),
                      const SizedBox(height: 24),
                      _buildDetailsCard(),
                      const SizedBox(height: 24),
                      _buildApprovalCard(),
                      const SizedBox(height: 100), // Space for fab/bottom
                    ],
                  ),
                ),
      floatingActionButton: _canCancel()
          ? FloatingActionButton.extended(
              onPressed: _cancelRequest,
              backgroundColor: Colors.red,
              icon: const Icon(Icons.cancel, color: Colors.white),
              label: const Text('Cancel Request', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  bool _canCancel() {
    if (_loading || _error != null || _data == null) return false;
    final user = ref.read(authProvider).user;
    if (user?.role != 'student') return false;
    final status = _data!['overall_status'];
    return status == 'pending_faculty' || status == 'pending_warden';
  }

  Widget _buildHeader() {
    final status = _data?['overall_status'] ?? 'unknown';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _data?['reason'] ?? 'No Reason',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _StatusChip(status: status),
      ],
    );
  }

  Widget _buildTimeline() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Approval Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StatusTimeline(status: _data?['overall_status'] ?? 'pending_faculty'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final dep = _data?['departure_datetime'] != null 
        ? DateFormat('MMM dd, hh:mm a').format(DateTime.parse(_data?['departure_datetime']))
        : '-';
    final ret = _data?['expected_return_datetime'] != null 
        ? DateFormat('MMM dd, hh:mm a').format(DateTime.parse(_data?['expected_return_datetime']))
        : '-';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(Icons.location_on_outlined, 'Destination', _data?['destination'] ?? '-'),
            const Divider(),
            _buildDetailRow(Icons.calendar_today_outlined, 'Departure', dep),
            const Divider(),
            _buildDetailRow(Icons.keyboard_return_outlined, 'Expected Return', ret),
            if (_data?['actual_departure_time'] != null) ...[
              const Divider(),
              _buildDetailRow(Icons.exit_to_app, 'Actual Departure', 
                DateFormat('MMM dd, hh:mm a').format(DateTime.parse(_data?['actual_departure_time']))),
            ],
            if (_data?['actual_return_time'] != null) ...[
              const Divider(),
              _buildDetailRow(Icons.home_outlined, 'Actual Return', 
                DateFormat('MMM dd, hh:mm a').format(DateTime.parse(_data?['actual_return_time']))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Approval Details', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildApprovalRow('Faculty', _data?['faculty_status'], _data?['faculty_remarks']),
            const SizedBox(height: 12),
            _buildApprovalRow('Warden', _data?['warden_status'], _data?['warden_remarks']),
            if (_data?['room_number'] != null) ...[
              const Divider(),
              _buildDetailRow(Icons.room_outlined, 'Room', '${_data?['room_number']} (${_data?['room_details']})'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildApprovalRow(String role, String? status, String? remarks) {
    final color = status == 'approved' ? Colors.green : (status == 'denied' ? Colors.red : Colors.orange);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(status == 'approved' ? Icons.check : (status == 'denied' ? Icons.close : Icons.pending), 
            size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (remarks != null && remarks.isNotEmpty)
                Text(remarks, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Text(status?.toUpperCase() ?? 'PENDING', 
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ],
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
      case 'approved': color = Colors.green; break;
      case 'completed': color = Colors.blue; break;
      case 'out': color = Colors.deepPurple; break;
      case 'expired':
      case 'cancelled':
        color = Colors.grey; break;
      default: color = status.contains('denied') ? Colors.red : Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
