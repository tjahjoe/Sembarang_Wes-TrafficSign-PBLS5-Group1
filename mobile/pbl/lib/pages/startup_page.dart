import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl/pages/login_page.dart';
import 'package:pbl/pages/home_page.dart';
import 'package:pbl/data/data_provider.dart';

class StartupPage extends StatefulWidget
{
  const StartupPage({super.key});
  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage>
{
  bool? _isLoggedIn;

  Future<void> _checkLoginStatus() async
  {
    final DataProvider provider = context.read<DataProvider>();
    final bool isLoggedIn = await provider.isLoggedIn();

    if (!mounted) return;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  void initState()
  {
    super.initState();
    _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context)
  {
    if (_isLoggedIn == null)
    {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Logika sudah pernah login
    return _isLoggedIn! ? const HomePage() : const LoginPage();
  }
}