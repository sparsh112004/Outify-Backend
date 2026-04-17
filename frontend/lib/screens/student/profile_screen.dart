import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/outing_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/requests_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _departmentController = TextEditingController();
  final _roomNumberController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Defer initialization to after build to read provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        if (user.department != null) _departmentController.text = user.department!;
        if (user.roomNumber != null) _roomNumberController.text = user.roomNumber!;
        if (user.gender != null) _selectedGender = user.gender;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _departmentController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final notifier = ref.read(authProvider.notifier);
    try {
      await notifier.updateProfile(
        department: _departmentController.text.trim(),
        roomNumber: _roomNumberController.text.trim(),
        gender: _selectedGender,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'About'),
            Tab(text: 'My QR'),
          ],
        ),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : TabBarView(
              controller: _tabController,
              children: [
                // ABOUT TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 32, color: Theme.of(context).primaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'College ID: ${user.collegeId ?? '-'}',
                        textAlign: TextAlign.center,
                      ),
                      const Divider(height: 32),
                      Text('Additional Details', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Department / Course',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedGender = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _roomNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Hostel & Room Details',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: auth.isLoading ? null : _saveProfile,
                        child: auth.isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Profile'),
                      ),
                    ],
                  ),
                ),

                // MY QR TAB
                Consumer(
                  builder: (context, ref, child) {
                    final req = ref.watch(requestsProvider);
                    OutingRequest? approvedRequest;
                    try {
                      approvedRequest = req.items.where((r) => r.overallStatus == 'approved').first;
                    } catch (_) {}

                    final payload = jsonEncode({
                      'userId': user.id,
                      if (approvedRequest != null) 'outingRequestId': approvedRequest.id,
                    });

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (approvedRequest != null) ...[
                            Text('Approved Request: #${approvedRequest.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Reason: ${approvedRequest.reason}'),
                          ] else
                            const Text('No approved outing requests'),
                          const SizedBox(height: 24),
                          QrImageView(
                            data: payload,
                            size: 260,
                          ),
                          const SizedBox(height: 16),
                          const Text('Show this QR at the gate', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
