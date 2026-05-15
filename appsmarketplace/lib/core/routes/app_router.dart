import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:appsmarketplace/core/services/auth_provider.dart';
import 'package:appsmarketplace/core/services/secure_storage.dart';

// Import Pages
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/Register_page.dart';
import '../features/auth/presentation/pages/Verify_email_page.dart';
import '../features/auth/presentation/pages/dashboard_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashPage(),
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    verifyEmail: (_) => const VerifyEmailPage(),

    // Dashboard tetap dijaga AuthGuard
    dashboard: (_) => const AuthGuard(child: DashboardPage()),
  };
}

//
// ================= AUTH GUARD =================
//
class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.authenticated => child,
      AuthStatus.emailNotVerified => const VerifyEmailPage(),
      AuthStatus.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      _ => const LoginPage(),
    };
  }
}

//
// ================= SPLASH PAGE =================
//
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    final firebaseUser = auth.firebaseUser;
    final backendToken = await SecureStorage.getToken();

    debugPrint("SPLASH CHECK:");
    debugPrint("FirebaseUser: $firebaseUser");
    debugPrint("BackendToken: $backendToken");

    if (firebaseUser != null && backendToken != null) {
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
