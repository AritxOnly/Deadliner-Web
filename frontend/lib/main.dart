import 'package:flutter/material.dart';
import 'package:frontend/homepage.dart';
import 'package:frontend/screens/setting_screen.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:frontend/screens/users_page.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsModel(),
      child: const DeadlinerApp(),
    ),
  );
}

class DeadlinerApp extends StatelessWidget {
  const DeadlinerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    return MaterialApp(
      title: 'Deadliner-Web',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.accentColor, // 使用设置中的强调色
          brightness: Brightness.light,
          dynamicSchemeVariant: settings.dynamicSchemeVariant,
          // DynamicSchemeVariant.expressive
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.accentColor, // 使用设置中的强调色
          brightness: Brightness.dark,
          dynamicSchemeVariant: settings.dynamicSchemeVariant,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkLoginAndMaybeShow(),
    );
  }

  Future<void> _checkLoginAndMaybeShow() async {
    final already = await AuthUtils().checkLoginStatus();
    if (!already) {
      // 强制跳转 UsersPage，并等待它 pop 回来
      final didLogin = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const UsersPage()));
      // 如果登录成功（UsersPage pop 了 true），就刷新自己
      if (didLogin == true && mounted) {
        setState(() {
          /* nothing special, 只是 rebuild HomePage */
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage(title: 'Deadliner');
  }
}
