import 'package:flutter/material.dart';
import 'package:frontend/screens/users_page.dart';
import 'package:frontend/utils/web_utils.dart';

/// 用户认证工具类
class AuthUtils {
  // 单例模式
  static final AuthUtils _instance = AuthUtils._internal();
  factory AuthUtils() => _instance;
  AuthUtils._internal();

  final WebUtils _webUtils = WebUtils();

  // 用户是否已登录的标志
  bool _isLoggedIn = false;

  // 获取登录状态
  // ignore: unnecessary_getters_setters
  bool get isLoggedIn => _isLoggedIn;

  // 设置登录状态
  set isLoggedIn(bool value) {
    _isLoggedIn = value;
  }

  // 检查用户是否已登录
  Future<bool> checkLoginStatus() async {
    // TODO: 实现实际的登录状态检查，例如从本地存储或API获取
    // 这里暂时返回假数据
    await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络请求
    return _isLoggedIn;
  }

  // 在应用启动时检查登录状态并显示用户页面
  void checkAndShowLoginOnStartup(BuildContext context) async {
    final bool needLogin = !(await checkLoginStatus());

    if (needLogin) {
      // 如果用户未登录，显示登录页面
      if (context.mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const UsersPage()));
      }
    }
  }

  // 登录方法
  Future<bool> login(String username, String password) async {
    final result = await _webUtils.login(username, password);
    _isLoggedIn = result;
    return result;
  }

  // 注册方法
  Future<bool> register(String username, String password) async {
    final result = await _webUtils.register(username, password);
    _isLoggedIn = result;
    return result;
  }

  // 退出登录
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络请求
    _isLoggedIn = false;
  }
}
