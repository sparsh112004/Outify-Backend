import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/outing_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/requests_provider.dart';

class QrDisplayScreen extends ConsumerWidget {
  const QrDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final req = ref.watch(requestsProvider);

    // Show QR for the first approved outing (if any). Otherwise fallback to user ID.
    OutingRequest? approvedRequest;
    try {
      approvedRequest = req.items.where((r) => r.overallStatus == 'approved').first;
    } catch (_) {
      // none found
    }

    final payload = jsonEncode({
      'userId': user?.id,
      if (approvedRequest != null) 'outingRequestId': approvedRequest.id,
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My QR')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user == null) const Text('Not logged in'),
            if (user != null) ...[
              Text(user.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(user.email),
              const SizedBox(height: 8),
              if (approvedRequest != null) ...[
                Text('Approved Request: #${approvedRequest.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Reason: ${approvedRequest.reason}'),
              ] else
                const Text('No approved outing requests'),
              const SizedBox(height: 16),
              QrImageView(
                data: payload,
                size: 260,
              ),
              const SizedBox(height: 8),
              const Text('Show this QR at the gate'),
            ]
          ],
        ),
      ),
    );
  }
}
