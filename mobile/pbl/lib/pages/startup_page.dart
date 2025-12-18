// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl/pages/login_page.dart';
import 'package:pbl/pages/home_page.dart';
import 'package:pbl/data/data_provider.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});
  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool? _isLoggedIn;

  Future<void> _checkLoginStatus() async {
    final DataProvider provider = context.read<DataProvider>();
    final bool isLoggedIn = await provider.isLoggedIn();

    if (!mounted) return;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A2A2A), Color(0xFF4A4A4A)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon dengan gradient container
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade600, Colors.amber.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.traffic,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Loading indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.amber.shade600,
                      ),
                      strokeWidth: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Text
                const Text(
                  'Traffic Sign Detector',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Memuat aplikasi...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Logika sudah pernah login
    return _isLoggedIn! ? const HomePage() : const LoginPage();
  }
}
