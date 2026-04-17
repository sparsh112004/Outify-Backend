import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/department_provider.dart';

class AdminEditUserScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const AdminEditUserScreen({super.key, required this.user});

  @override
  ConsumerState<AdminEditUserScreen> createState() => _AdminEditUserScreenState();
}

class _AdminEditUserScreenState extends ConsumerState<AdminEditUserScreen> {
  final _name = TextEditingController();
  final _department = TextEditingController();
  final _password = TextEditingController();
  
  String _selectedRole = 'faculty';
  String? _selectedGender;
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _name.text = widget.user.name;
    _selectedDepartment = widget.user.department;
    _selectedRole = const ['student', 'faculty', 'warden', 'security', 'admin'].contains(widget.user.role)
        ? widget.user.role
        : 'faculty';
    _selectedGender = const ['male', 'female', 'other'].contains(widget.user.gender)
        ? widget.user.gender
        : null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(departmentProvider.notifier).fetchDepartments();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _department.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.isEmpty) return;
    ref.read(adminProvider.notifier).updateUser(
          widget.user.id,
          name: _name.text.trim(),
          role: _selectedRole,
          department: _selectedDepartment,
          gender: _selectedGender ?? '',
          password: _password.text.isEmpty ? null : _password.text,
        );
  }

  void _showResetPasswordDialog() {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Account Password'),
        content: TextField(
          controller: passCtrl,
          decoration: const InputDecoration(labelText: 'New Strong Password'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (passCtrl.text.isNotEmpty) {
                ref.read(adminProvider.notifier).updateUser(widget.user.id, password: passCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to success state to pop the screen
    ref.listen<AdminState>(adminProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading && next.error == null && next.successMessage != null && next.successMessage!.toLowerCase().contains('updated')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Update Personnel Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Editing: ${widget.user.email}',
                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
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
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                   DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Personnel Role', prefixIcon: Icon(Icons.admin_panel_settings_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                      DropdownMenuItem(value: 'faculty', child: Text('Faculty Member')),
                      DropdownMenuItem(value: 'warden', child: Text('Hostel Warden')),
                      DropdownMenuItem(value: 'security', child: Text('Security Guard')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
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
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),
                  const SizedBox(height: 20),
                  Consumer(
                    builder: (context, ref, child) {
                      final deptState = ref.watch(departmentProvider);
                      return DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_outlined)),
                        items: deptState.departments.map((d) => DropdownMenuItem(
                          value: d.name,
                          child: Text(d.name),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedDepartment = val),
                        hint: deptState.isLoading ? const Text('Loading...') : const Text('Select Department'),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (adminState.error != null) ...[
              Text(adminState.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: adminState.isLoading ? null : _submit,
                child: adminState.isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showResetPasswordDialog,
              icon: const Icon(Icons.lock_reset_rounded, size: 20),
              label: const Text('Reset Password'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange[800],
                side: BorderSide(color: Colors.orange[800]!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

