import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl/components/password_field.dart';
import 'package:pbl/components/username_field.dart';
import 'package:pbl/pages/home_page.dart';
import 'package:pbl/data/data_provider.dart';

class LoginPage extends StatefulWidget {
  final String title = 'Traffic Sign Detector - Login';

  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  String namaPengguna = '';
  String sandi = '';

  Future<void> _login(BuildContext context) async {
    DataProvider provider = context.read<DataProvider>();
    if (namaPengguna == 'user' && sandi == '123') {
      await provider.saveLoginInfo(namaPengguna, sandi);

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
              (Route<dynamic> route) => false,
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama pengguna atau sandi salah!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: Text(widget.title),
        elevation: 2,
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A2A2A),
              Color(0xFF4A4A4A),
            ],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              padding: const EdgeInsets.all(24),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Icon besar
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: const Icon(
                      Icons.traffic,
                      size: 110,
                      color: Colors.amber,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(2, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Label Username
                  const Text(
                    'Nama Pengguna:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  UsernameField(
                    onChanged: (value) => namaPengguna = value,
                  ),

                  const SizedBox(height: 20),

                  // Label Password
                  const Text(
                    'Sandi:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  PasswordField(
                    onChanged: (value) => sandi = value,
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        elevation: 4,
                      ),
                      onPressed: () => _login(context),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}