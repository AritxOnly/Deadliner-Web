import 'package:flutter/material.dart';
import 'package:frontend/utils/task_utils.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Stack(
          children: [
            Center(child: Text('Task Screen')),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () {
                  TaskUtils.onFABPressed();
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      );
  }
}
