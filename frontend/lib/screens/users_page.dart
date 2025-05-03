import 'package:flutter/material.dart';
import 'package:frontend/utils/auth_utils.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  // 用户登录状态
  bool isLoggedIn = false;
  // 是否显示注册表单
  bool showRegisterForm = false;

  @override
  void initState() {
    super.initState();
    // 检查登录状态
    _checkLoginStatus();
  }

  // 检查登录状态
  void _checkLoginStatus() async {
    final loggedIn = await AuthUtils().checkLoginStatus();
    if (mounted) {
      setState(() {
        isLoggedIn = loggedIn;
      });
    }
  }

  // 表单控制器
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 登录处理
  void _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('用户名和密码不能为空')));
      return;
    }

    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final success = await AuthUtils().login(
        _usernameController.text,
        _passwordController.text,
      );

      if (context.mounted) {
        Navigator.pop(context); // 关闭加载指示器

        if (success) {
          setState(() {
            isLoggedIn = true;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('登录成功')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('登录失败，请检查用户名和密码')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 关闭加载指示器
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登录出错: $e')));
      }
    }
  }

  // 注册处理
  void _handleRegister() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('所有字段都不能为空')));
      return;
    }

    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final success = await AuthUtils().register(
        _usernameController.text,
        _passwordController.text,
      );

      if (context.mounted) {
        Navigator.pop(context); // 关闭加载指示器

        if (success) {
          setState(() {
            isLoggedIn = true;
            showRegisterForm = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('注册成功并已登录')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('注册失败，请稍后再试')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 关闭加载指示器
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('注册出错: $e')));
      }
    }
  }

  // 退出登录
  void _handleLogout() async {
    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await AuthUtils().logout();

      if (context.mounted) {
        Navigator.pop(context); // 关闭加载指示器
        setState(() {
          isLoggedIn = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已退出登录')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 关闭加载指示器
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('退出登录出错: $e')));
      }
    }
  }

  // 切换到注册表单
  void _toggleRegisterForm() {
    setState(() {
      showRegisterForm = !showRegisterForm;
    });
  }

  // 构建登录表单
  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('用户登录', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _toggleRegisterForm,
                child: const Text('没有账号？注册'),
              ),
              FilledButton(onPressed: _handleLogin, child: const Text('登录')),
            ],
          ),
        ],
      ),
    );
  }

  // 构建注册表单
  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('用户注册', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _toggleRegisterForm,
                child: const Text('已有账号？登录'),
              ),
              FilledButton(onPressed: _handleRegister, child: const Text('注册')),
            ],
          ),
        ],
      ),
    );
  }

  // 构建用户信息页面
  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            _usernameController.text.isEmpty ? '用户' : _usernameController.text,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('任务历史'),
            onTap: () {
              // TODO: 导航到任务历史页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('账户设置'),
            onTap: () {
              // TODO: 导航到账户设置页面
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户'), centerTitle: false),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child:
                  isLoggedIn
                      ? _buildUserProfile()
                      : (showRegisterForm
                          ? _buildRegisterForm()
                          : _buildLoginForm()),
            ),
          ),
        ),
      ),
    );
  }
}
