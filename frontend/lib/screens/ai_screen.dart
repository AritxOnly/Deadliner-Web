import 'package:flutter/material.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const Center(child: Text('AI')));
  }
}
