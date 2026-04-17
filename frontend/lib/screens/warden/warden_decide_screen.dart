import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/requests_provider.dart';

class WardenDecideScreen extends ConsumerStatefulWidget {
  final int requestId;

  const WardenDecideScreen({super.key, required this.requestId});

  @override
  ConsumerState<WardenDecideScreen> createState() => _WardenDecideScreenState();
}

class _WardenDecideScreenState extends ConsumerState<WardenDecideScreen> {
  final _room = TextEditingController();
  final _details = TextEditingController();
  final _remarks = TextEditingController();
  bool _emailParent = false;

  @override
  void dispose() {
    _room.dispose();
    _details.dispose();
    _remarks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final req = ref.watch(requestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Warden Decision')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _room,
              decoration: const InputDecoration(labelText: 'Room number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _details,
              decoration: const InputDecoration(labelText: 'Room details'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarks,
              decoration: const InputDecoration(labelText: 'Remarks (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Send confirmation email to Parent'),
              value: _emailParent,
              onChanged: (val) => setState(() => _emailParent = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            if (req.error != null) ...[
              Text(req.error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: req.isLoading
                        ? null
                        : () async {
                            await ref.read(requestsProvider.notifier).wardenDecide(
                                  requestId: widget.requestId,
                                  decision: 'approved',
                                  roomNumber: _room.text.trim(),
                                  roomDetails: _details.text.trim(),
                                  remarks: _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
                                );
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                    child: req.isLoading ? const CircularProgressIndicator() : const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: req.isLoading
                        ? null
                        : () async {
                            await ref.read(requestsProvider.notifier).wardenDecide(
                                  requestId: widget.requestId,
                                  decision: 'rejected',
                                  roomNumber: _room.text.trim(),
                                  roomDetails: _details.text.trim(),
                                  remarks: _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
                                );
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
