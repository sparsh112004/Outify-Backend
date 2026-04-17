import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _collegeId = TextEditingController();
  String? _selectedDepartment;
  String? _selectedGender;

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
    _collegeId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              const Color(0xFF1E293B),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: -5),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Creation Account',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your details to register as a student',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _password,
                        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.password_outlined)),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _collegeId,
                        decoration: const InputDecoration(labelText: 'College ID (optional)', prefixIcon: Icon(Icons.badge_outlined)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_outlined)),
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('Male')),
                                DropdownMenuItem(value: 'female', child: Text('Female')),
                                DropdownMenuItem(value: 'other', child: Text('Other')),
                              ],
                              onChanged: (val) => setState(() => _selectedGender = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final deptState = ref.watch(departmentProvider);
                                return DropdownButtonFormField<String>(
                                  value: _selectedDepartment,
                                  decoration: const InputDecoration(labelText: 'Dept', prefixIcon: Icon(Icons.business_outlined)),
                                  items: deptState.departments.map((d) => DropdownMenuItem(
                                    value: d.name,
                                    child: Text(d.name),
                                  )).toList(),
                                  onChanged: (val) => setState(() => _selectedDepartment = val),
                                  hint: deptState.isLoading ? const Text('...') : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (auth.error != null) ...[
                        Text(auth.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  await ref.read(authProvider.notifier).registerStudent(
                                        name: _name.text.trim(),
                                        email: _email.text.trim(),
                                        password: _password.text,
                                        collegeId: _collegeId.text.trim().isEmpty ? null : _collegeId.text.trim(),
                                        department: _selectedDepartment,
                                        gender: _selectedGender,
                                      );
                                  if (ref.read(authProvider).user != null && mounted) {
                                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                                  }
                                },
                          child: auth.isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Create Account'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Already have an account? Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
