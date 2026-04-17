import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_provider.dart';
import '../../providers/department_provider.dart';
import '../../utils/theme.dart';

class AdminCreateUserScreen extends ConsumerStatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  ConsumerState<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends ConsumerState<AdminCreateUserScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _department = TextEditingController();
  String _selectedRole = 'faculty';
  String? _selectedGender;
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(departmentProvider.notifier).fetchDepartments();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _department.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_name.text.isEmpty || _email.text.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
      return;
    }

    await ref.read(adminProvider.notifier).createUser(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          role: _selectedRole,
          department: _selectedDepartment,
          gender: _selectedGender,
        );

    if (!mounted) return;

    final state = ref.read(adminProvider);
    if (state.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage ?? 'Success')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Staff Personnel')),
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
                   DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Personnel Role'),
                    items: const [
                      DropdownMenuItem(value: 'faculty', child: Text('Faculty Staff')),
                      DropdownMenuItem(value: 'warden', child: Text('Hostel Warden')),
                      DropdownMenuItem(value: 'security', child: Text('Security Personnel')),
                    ],
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Official Email', prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Initial Password', prefixIcon: Icon(Icons.lock_outline)),
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
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(labelText: 'Gender Identification', prefixIcon: Icon(Icons.wc_outlined)),
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
                        decoration: const InputDecoration(labelText: 'Assigned Department', prefixIcon: Icon(Icons.business_outlined)),
                        items: deptState.departments.map((d) => DropdownMenuItem(
                          value: d.name,
                          child: Text(d.name),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedDepartment = val),
                        hint: deptState.isLoading ? const Text('Fetching departments...') : const Text('Select Department'),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (admin.error != null) ...[
              Text(admin.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: admin.isLoading ? null : _submit,
                child: admin.isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Register Personnel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
