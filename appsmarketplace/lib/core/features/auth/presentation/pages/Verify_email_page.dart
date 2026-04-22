import 'package:appsmarketplace/core/routes/app_router.dart';
import 'package:appsmarketplace/core/services/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../widgets/auth_header.dart';
import '../widgets/custom_button.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _timer;
  bool _resendCooldown = false;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    // Memulai pengecekan otomatis setiap 3 detik
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Logika Polling untuk mengecek status verifikasi tanpa mengubah UI
  void _startPolling() {
  _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
    final auth = context.read<AuthProvider>();


  Future<void> _resendEmail() async {
    if (_resendCooldown) return;
    try {
      // Menggunakan fungsi kirim ulang dari provider
      await context.read<AuthProvider>().firebaseUser?.sendEmailVerification();

      setState(() {
        _resendCooldown = true;
        _countdown = 60;
      });

      Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          _countdown--;
        });
        if (_countdown <= 0) {
          t.cancel();
          setState(() => _resendCooldown = false);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verifikasi sudah dikirim ulang')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim email: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().firebaseUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AuthHeader(
                icon: Icons.mark_email_unread_outlined,
                title: 'Verifikasi Email Kamu',
                subtitle:
                    'Kami sudah mengirim link verifikasi ke email di bawah ini. Silakan klik link tersebut lalu tunggu sebentar.',
                iconColor: Colors.orange,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  user?.email ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Mengecek status verifikasi...'),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: _resendCooldown
                    ? 'Kirim Ulang ($_countdown s)'
                    : 'Kirim Ulang Email',
                variant: ButtonVariant.outlined,
                onPressed: _resendCooldown ? null : _resendEmail,
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Logout / Ganti Akun',
                variant: ButtonVariant.text,
                onPressed: () async {
                  _timer?.cancel();
                  await context.read<AuthProvider>().logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, AppRouter.login);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
