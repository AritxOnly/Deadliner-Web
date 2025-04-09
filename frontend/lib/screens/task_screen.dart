import 'package:flutter/material.dart';
import 'package:frontend/utils/task_utils.dart';
import 'package:frontend/utils/web_utils.dart';
import 'package:http/http.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final List<Map<String, dynamic>> _taskData = [];
  late WebUtils webUtils;

  void exampleInit() {
    _taskData.addAll([
      {
        'title': '项目原型设计',
        'note': '需完成用户流程设计',
        'remainingTime': '剩余3天',
        'progress': 0.6,
      },
      {
        'title': '开发文档编写',
        'note': '',
        'remainingTime': '剩余12小时',
        'progress': 0.2,
      },
    ]);
  }

  @override
  void initState() {
    super.initState();

    webUtils = WebUtils();

    // 启动第二个线程尝试连接API服务器
    Future<void> _initializeConnection() async {
      try {
        final response = await webUtils.isWebAvailable();
        if (response) {
          // 连接成功，获取DDL数据
          final ddlItems = await webUtils.getAllDDLs();
          setState(() {
            _taskData.clear(); // 清空现有数据
            for (var item in ddlItems) {
              // 将DDLItem转换为任务数据格式
              _taskData.add({
                'title': item.name,
                'note': item.note,
                'remainingTime': item.endTime,
                'progress': 0.0,
              });
            }
          });
        }
      } catch (e) {
        // 连接失败，显示错误信息
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('无法连接到服务器: $e')));
        }
      }
    }

    _initializeConnection();
  }

  void addTask(String title, String note, String timeText) {
    setState(() {
      _taskData.add({
        'title': title,
        'note': note,
        'remainingTime': timeText,
        'progress': 0.0,
      });
    });
  }

  void updateTask(int index, String title, String note, String timeText) {
    setState(() {
      _taskData[index]['title'] = title;
      _taskData[index]['note'] = note;
      _taskData[index]['remainingTime'] = timeText;
    });
  }

  void deleteTask(int index) {
    setState(() {
      _taskData.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _taskData.length,
            itemBuilder: (context, index) {
              final task = _taskData[index];
              return Column(
                children: [
                  DeadlineItem(
                    title: task['title'],
                    note: task['note'],
                    remainingTime: task['remainingTime'],
                    progress: task['progress'],
                    onTap: () {
                      TaskUtils.showEditDialog(
                        context,
                        initialTitle: task['title'],
                        initialNote: task['note'],
                        initialTime: task['remainingTime'],
                        onConfirm: (newTitle, newNote, newTime) {
                          updateTask(index, newTitle, newNote, newTime);
                        },
                        onDelete: () {
                          deleteTask(index);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () {
                TaskUtils.onFABPressed(context, onTaskAdd: addTask);
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class DeadlineItem extends StatelessWidget {
  final String title;
  final String remainingTime;
  final String note;
  final double progress;
  final VoidCallback? onTap;

  const DeadlineItem({
    super.key,
    required this.title,
    required this.remainingTime,
    this.note = "",
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(context),
              const SizedBox(height: 8),
              _buildNoteRow(context),
              const SizedBox(height: 12),
              _buildProgressBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          remainingTime,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 8,
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
    );
  }
}

class TaskUtils {
  static void onFABPressed(
    BuildContext context, {
    required void Function(String title, String note, String timeText)
    onTaskAdd,
  }) {
    _showTaskDialog(context, onConfirm: onTaskAdd);
  }

  static void showEditDialog(
    BuildContext context, {
    required String initialTitle,
    required String initialNote,
    required String initialTime,
    required void Function(String title, String note, String timeText)
    onConfirm,
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
    required void Function(String title, String note, String timeText)
    onConfirm,
    VoidCallback? onDelete,
  }) {
    final titleController = TextEditingController(text: initialTitle);
    final noteController = TextEditingController(text: initialNote);
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String formattedDateTime() {
              if (selectedDate == null && selectedTime == null)
                return initialTime;
              final date =
                  selectedDate != null
                      ? "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"
                      : "";
              final time =
                  selectedTime != null ? selectedTime!.format(context) : "";
              return "$date $time".trim();
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(onDelete == null ? '添加任务' : '编辑任务'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: '任务标题',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton(
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
                        FilledButton(
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
                    Row(
                      children: [
                        const Text('截止时间：'),
                        const SizedBox(width: 8),
                        Text(formattedDateTime()),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                if (onDelete != null)
                  TextButton(onPressed: onDelete, child: const Text('删除')),
                FilledButton(
                  onPressed: () {
                    onConfirm(
                      titleController.text,
                      noteController.text,
                      formattedDateTime(),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
