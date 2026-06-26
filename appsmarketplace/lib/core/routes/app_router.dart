import 'package:appsmarketplace/core/services/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import Pages
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/Register_page.dart';
import '../features/auth/presentation/pages/Verify_email_page.dart';
import '../features/auth/presentation/pages/dashboard_page.dart';
import '../features/auth/presentation/pages/transaction_success_page.dart';

import '../services/secure_storage.dart';
import '../services/global_institute_pay_service.dart';
import '../services/notification_service.dart';
import '../features/cart/presentation/providers/cart_provider.dart';

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

    // Dashboard dibungkus AuthGuard (Si Satpam)
    dashboard: (_) => const AuthGuard(child: DashboardPage()),
  };
}

// --- TULIS KODE INI DI BAWAH CLASS APPROUTER (Masih di file yang sama) ---

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Memantau status login dari AuthProvider
    // Status ini didapat setelah login sukses atau cek token di awal
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.authenticated => child, // Jika OK, tampilkan Dashboard
      AuthStatus.emailNotVerified =>
        const VerifyEmailPage(), // Jika login tapi belum klik link email
      _ => const LoginPage(), // Jika belum login, tendang ke Login Page
    };
  }
}

// SplashPage: cek token tersimpan, redirect otomatis
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

    // Cold start via deeplink: user baru saja bayar di E-Money
    // Jangan logout — langsung tampilkan status transaksi
    final pending = GlobalInstitutePayService().consumePendingCallback();
    if (pending != null && pending.isSuccess) {
      // Kosongkan keranjang dan kirim notifikasi
      context.read<CartProvider>().clearLocal();
      await NotificationService().showPaymentSuccess(
        amount: pending.amount ?? 0,
        reference: pending.reference,
        transactionId: pending.transactionId,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionSuccessPage(
            amount: pending.amount ?? 0,
            reference: pending.reference,
            transactionId: pending.transactionId,
            paymentMethod: 'Global Institute Pay',
          ),
        ),
      );
      return;
    }

    // Normal flow — user wajib login manual setiap buka app
    await SecureStorage.deleteToken();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
