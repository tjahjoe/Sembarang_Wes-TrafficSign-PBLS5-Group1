import 'package:shared_preferences/shared_preferences.dart';

class LoginInfo
{
  String username;
  String password;
  bool isLoggedIn;

  LoginInfo({
    this.username = '',
    this.password = '',
    this.isLoggedIn = false,
  });

  Future<void> saveToSharedPreferences() async
  {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  // Method statis untuk membaca data dari Shared Preferences
  static Future<LoginInfo> fromSharedPreferences() async
  {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    final password = prefs.getString('password') ?? '';
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return LoginInfo(
        username: username,
        password: password,
        isLoggedIn: isLoggedIn
    );
  }

  // Method statis untuk menghapus data dari Shared Preferences
  static Future<void> deleteFromSharedPreferences() async
  {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('username');
    prefs.remove('password');
    prefs.remove('isLoggedIn');
  }

  @override
  String toString()
  {
    return 'LoginInfo{username: $username, password: $password, isLoggedIn: $isLoggedIn}';
  }
}