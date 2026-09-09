import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/controllers/admin_controller.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
      ],
      child: const LubeMonitorApp(),
    ),
  );
}

class LubeMonitorApp extends StatelessWidget {
  const LubeMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lube Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppEntry(),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  late Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _checkSession();
  }

  Future<bool> _checkSession() async {
    await Future.microtask(() {});
    if (!mounted) return false;
    final valid = await context.read<AuthController>().checkSession();
    if (valid && mounted) {
      context.read<AdminController>().loadClients();
    }
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
