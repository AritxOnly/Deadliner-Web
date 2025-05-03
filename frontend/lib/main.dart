import 'package:flutter/material.dart';
import 'package:frontend/homepage.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:frontend/screens/users_page.dart';

void main() {
  runApp(const DeadlinerApp());
}

class DeadlinerApp extends StatelessWidget {
  const DeadlinerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deadliner-Web',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
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
