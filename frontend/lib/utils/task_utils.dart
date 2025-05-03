import 'package:flutter/material.dart';

class TaskUtils {
  static void onFABPressed(BuildContext context, {
    required void Function(String title, String note, String timeText) onTaskAdd,
  }) {
    _showTaskDialog(context, onConfirm: onTaskAdd);
  }

  static void showEditDialog(
    BuildContext context, {
    required String initialTitle,
    required String initialNote,
    required String initialTime,
    required void Function(String title, String note, String timeText) onConfirm,
    required VoidCallback onDelete,
  }) {
    _showTaskDialog(
      context,
      initialTitle: initialTitle,
      initialNote: initialNote,
      initialTime: initialTime,
      onConfirm: onConfirm,
      onDelete: onDelete,
    );
  }

  static void _showTaskDialog(
    BuildContext context, {
    String initialTitle = "",
    String initialNote = "",
    String initialTime = "",
    required void Function(String title, String note, String timeText) onConfirm,
    VoidCallback? onDelete,
  }) {
    final titleController = TextEditingController(text: initialTitle);
    final noteController = TextEditingController(text: initialNote);
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          String formattedDateTime() {
            if (selectedDate == null && selectedTime == null) return initialTime;
            final date = selectedDate != null
                ? "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"
                : "";
            final time = selectedTime != null ? selectedTime!.format(context) : "";
            return "$date $time".trim();
          }

          return AlertDialog(
            title: Text(onDelete == null ? '添加任务' : '编辑任务'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '任务标题'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: '备注'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        child: const Text('选择日期'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        child: const Text('选择时间'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formattedDateTime(),
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
            actions: [
              if (onDelete != null)
                TextButton(
                  onPressed: () {
                    onDelete();
                    Navigator.of(context).pop();
                  },
                  child: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final note = noteController.text.trim();
                  final timeText = formattedDateTime();
                  if (title.isNotEmpty) {
                    onConfirm(title, note, timeText);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        });
      },
    );
  }
}