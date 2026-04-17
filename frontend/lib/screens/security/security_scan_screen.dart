import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/requests_provider.dart';

class SecurityScanScreen extends ConsumerStatefulWidget {
  const SecurityScanScreen({super.key});

  @override
  ConsumerState<SecurityScanScreen> createState() => _SecurityScanScreenState();
}

class _SecurityScanScreenState extends ConsumerState<SecurityScanScreen> {
  bool _handled = false;

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scan Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _handled = false);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Scan Gate')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (_handled) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;

              setState(() => _handled = true);

              int? requestId;
              int? userId;
              
              try {
                final decoded = jsonDecode(raw);
                if (decoded is Map<String, dynamic>) {
                  if (decoded.containsKey('outingRequestId')) {
                    requestId = int.tryParse(decoded['outingRequestId'].toString());
                  } else if (decoded.containsKey('userId')) {
                    userId = int.tryParse(decoded['userId'].toString());
                  }
                }
              } catch (_) {
                // Not JSON, maybe a raw ID
                requestId = int.tryParse(raw);
              }

              if (requestId != null) {
                Navigator.of(context).pushReplacementNamed('/security/verify/$requestId');
              } else if (userId != null) {
                // Automated Lookup
                final outing = await ref.read(requestsProvider.notifier).findActiveRequest(userId);
                if (mounted) {
                  if (outing != null) {
                    Navigator.of(context).pushReplacementNamed('/security/verify/${outing.id}');
                  } else {
                    _showError('No active approved outing request found for this student for today.');
                  }
                }
              } else {
                _showError('Invalid QR Code. Please ensure the student is showing their Digital Pass.');
              }
            },
          ),
          if (_handled && ref.watch(requestsProvider).isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
