import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/users_page.dart';
import 'package:frontend/utils/web_utils.dart';

class AuthUtils {
  static const _prefsKeyLoggedIn = 'is_logged_in';

  // 单例
  static final AuthUtils _instance = AuthUtils._internal();
  factory AuthUtils() => _instance;
  AuthUtils._internal() {
    _loadLoginStatus();
  }

  final WebUtils _webUtils = WebUtils();
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  Future<void> _loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn =
        prefs.getBool(_prefsKeyLoggedIn) == true && _webUtils.isLoggedIn();
  }

  Future<void> _saveLoginStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyLoggedIn, value);
    _isLoggedIn = value;
  }

  Future<bool> checkLoginStatus() async {
    // 先从本地读
    await _loadLoginStatus();
    return _isLoggedIn;
  }

  void checkAndShowLoginOnStartup(BuildContext context) async {
    final needLogin = !(await checkLoginStatus());
    if (needLogin && context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const UsersPage()));
    }
  }

  Future<bool> login(String username, String password) async {
    final result = await _webUtils.login(username, password);
    await _saveLoginStatus(result);
    return result;
  }

  Future<bool> register(String username, String password) async {
    final result = await _webUtils.register(username, password);
    await _saveLoginStatus(result);
    return result;
  }

  Future<void> logout() async {
    _webUtils.logout();
    await _saveLoginStatus(false);
  }
}
