import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'utils/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/requests_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/faculty/faculty_home_screen.dart';
import 'screens/requests/request_detail_screen.dart';
import 'screens/security/security_home_screen.dart';
import 'screens/security/security_scan_screen.dart';
import 'screens/security/security_verify_screen.dart';
import 'screens/shared/role_profile_screen.dart';
import 'screens/student/new_request_screen.dart';
import 'screens/student/profile_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/admin_create_user_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'screens/warden/warden_decide_screen.dart';
import 'screens/warden/warden_home_screen.dart';
import 'services/local_storage.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  await NotificationService.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    print('DEBUG: MyApp build - auth.user: ${auth.user?.email}, role: ${auth.user?.role}');

    return MaterialApp(
      title: 'OutEase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: auth.user == null ? const LoginScreen() : const _RoleRouter(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/student/new': (_) => const NewRequestScreen(),
        '/student/profile': (_) => const ProfileScreen(),
        '/security/scan': (_) => const SecurityScanScreen(),
        '/profile': (_) => const RoleProfileScreen(),
        '/admin/create_user': (_) => const AdminCreateUserScreen(),
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        if (name.startsWith('/requests/')) {
          final idStr = name.replaceFirst('/requests/', '');
          final id = int.tryParse(idStr);
          if (id != null) {
            return MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: id));
          }
        }

        if (name.startsWith('/warden/decide/')) {
          final idStr = name.replaceFirst('/warden/decide/', '');
          final id = int.tryParse(idStr);
          if (id != null) {
            return MaterialPageRoute(builder: (_) => WardenDecideScreen(requestId: id));
          }
        }

        if (name.startsWith('/security/verify/')) {
          final idStr = name.replaceFirst('/security/verify/', '');
          final id = int.tryParse(idStr);
          if (id != null) {
            return MaterialPageRoute(builder: (_) => SecurityVerifyScreen(requestId: id));
          }
        }
        return null;
      },
    );
  }
}

class _RoleRouter extends ConsumerStatefulWidget {
  const _RoleRouter();

  @override
  ConsumerState<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends ConsumerState<_RoleRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final user = ref.read(authProvider).user;
    if (user?.role == 'student') {
      ref.read(requestsProvider.notifier).fetchStudentRequests();
    } else if (user?.role == 'faculty') {
      ref.read(requestsProvider.notifier).fetchFacultyPending();
    } else if (user?.role == 'warden') {
      ref.read(requestsProvider.notifier).fetchWardenPending();
    } else if (user?.role == 'security') {
      ref.read(requestsProvider.notifier).fetchSecurityToday();
    }
    // Admin doesn't trigger requestsProvider
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (auth.user?.role == 'student') {
      print('DEBUG: Routing to StudentHomeScreen');
      return const StudentHomeScreen();
    }
    if (auth.user?.role == 'faculty') {
      print('DEBUG: Routing to FacultyHomeScreen');
      return const FacultyHomeScreen();
    }
    if (auth.user?.role == 'warden') {
      print('DEBUG: Routing to WardenHomeScreen');
      return const WardenHomeScreen();
    }
    if (auth.user?.role == 'security') {
      print('DEBUG: Routing to SecurityHomeScreen');
      return const SecurityHomeScreen();
    }
    if (auth.user?.role == 'admin') {
      print('DEBUG: Routing to AdminHomeScreen');
      return const AdminHomeScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Outing Management')),
      body: Center(
        child: Text('Role not wired yet: ${auth.user?.role ?? ''}'),
      ),
    );
  }
}
