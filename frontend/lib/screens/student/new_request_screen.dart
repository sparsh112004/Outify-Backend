import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/requests_provider.dart';
import '../../utils/theme.dart';

class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _reason = TextEditingController();
  final _destination = TextEditingController();
  final _roomNumber = TextEditingController();
  String? _selectedDepartment;
  int? _selectedFacultyId;

  DateTime? _departure;
  DateTime? _expectedReturn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(departmentProvider.notifier).fetchDepartments();
      final user = ref.read(authProvider).user;
      if (user?.roomNumber != null) {
        _roomNumber.text = user!.roomNumber!;
      }
      if (user?.department != null) {
        setState(() => _selectedDepartment = user?.department);
        ref.read(requestsProvider.notifier).fetchFaculties(user?.department);
      } else {
        ref.read(requestsProvider.notifier).fetchFaculties(null);
      }
    });
  }

  @override
  void dispose() {
    _reason.dispose();
    _destination.dispose();
    _roomNumber.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(BuildContext context, {DateTime? initial}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: initial ?? now,
    );
    if (date == null) return null;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial ?? now));
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final req = ref.watch(requestsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('New Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.premiumShadow,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _reason,
                    decoration: const InputDecoration(labelText: 'Purpose of Outing', hintText: 'Explain why you need to go out...'),
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _destination,
                    decoration: const InputDecoration(labelText: 'Destination Location'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _roomNumber,
                    decoration: const InputDecoration(labelText: 'Room & Hostel Details'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.premiumShadow,
              ),
              child: Column(
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final deptState = ref.watch(departmentProvider);
                      return DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: const InputDecoration(labelText: 'Academic Department'),
                        items: deptState.departments.map((d) => DropdownMenuItem(
                          value: d.name,
                          child: Text(d.name),
                        )).toList(),
                        onChanged: (val) {
                          setState(() => _selectedDepartment = val);
                          ref.read(requestsProvider.notifier).fetchFaculties(val);
                        },
                        hint: deptState.isLoading ? const Text('Loading...') : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    value: (req.faculties.any((f) => f.id == _selectedFacultyId)) ? _selectedFacultyId : null,
                    decoration: const InputDecoration(labelText: 'Approving Faculty Member'),
                    items: req.faculties.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                    onChanged: (val) => setState(() => _selectedFacultyId = val),
                    hint: const Text('Select your HOD / Class In-charge'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DateTimeBox(
                    label: 'Departure',
                    dateTime: _departure,
                    onTap: () async {
                      final dt = await _pickDateTime(context, initial: _departure);
                      if (dt != null) setState(() => _departure = dt);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateTimeBox(
                    label: 'Return',
                    dateTime: _expectedReturn,
                    onTap: () async {
                      final dt = await _pickDateTime(context, initial: _expectedReturn);
                      if (dt != null) setState(() => _expectedReturn = dt);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (req.error != null) ...[
              Text(req.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: req.isLoading
                    ? null
                    : () async {
                        if (_departure == null || _expectedReturn == null || _selectedFacultyId == null || _reason.text.isEmpty) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                           return;
                        }
                        await ref.read(requestsProvider.notifier).createRequest(
                              reason: _reason.text.trim(),
                              destination: _destination.text.trim().isEmpty ? null : _destination.text.trim(),
                              roomNumber: _roomNumber.text.trim().isEmpty ? null : _roomNumber.text.trim(),
                              department: _selectedDepartment,
                              facultyId: _selectedFacultyId!,
                              departure: _departure!,
                              expectedReturn: _expectedReturn!,
                            );
                        if (!mounted) return;
                        if (ref.read(requestsProvider).error == null) {
                          Navigator.of(context).pop();
                        }
                      },
                child: req.isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeBox extends StatelessWidget {
  final String label;
  final DateTime? dateTime;
  final VoidCallback onTap;

  const _DateTimeBox({required this.label, this.dateTime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, hh:mm a');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              dateTime != null ? format.format(dateTime!) : 'Choose...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: dateTime != null ? AppTheme.primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

