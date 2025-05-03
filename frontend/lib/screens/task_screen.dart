import 'package:flutter/material.dart';
import 'package:frontend/models/deadline_type.dart';
import 'package:frontend/utils/task_utils.dart';
import 'package:frontend/utils/web_utils.dart';
import 'package:frontend/utils/global_utils.dart';
import 'package:frontend/models/ddl_item.dart';
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
    Future<void> initializeConnection() async {
      try {
        final response = await webUtils.isWebAvailable();
        if (response) {
          // 连接成功，获取DDL数据
          final ddlItems = await webUtils.getAllDDLs();
          setState(() {
            _taskData.clear(); // 清空现有数据
            final now = DateTime.now();

            for (var item in ddlItems) {
              // 解析开始时间和结束时间
              final startTime = GlobalUtils.safeParseDateTime(item.startTime);
              final endTime = GlobalUtils.safeParseDateTime(item.endTime);

              // 计算进度
              double progress = 0.0;
              if (startTime != GlobalUtils.timeNull &&
                  endTime != GlobalUtils.timeNull) {
                // 如果当前时间在开始时间之前，进度为0
                if (now.isBefore(startTime)) {
                  progress = 0.0;
                }
                // 如果当前时间在结束时间之后，进度为1
                else if (now.isAfter(endTime)) {
                  progress = 1.0;
                }
                // 否则，计算进度比例
                else {
                  final totalDuration =
                      endTime.difference(startTime).inMilliseconds;
                  final elapsedDuration =
                      now.difference(startTime).inMilliseconds;
                  progress =
                      totalDuration > 0 ? elapsedDuration / totalDuration : 0.0;
                  // 确保进度在0-1之间
                  progress = progress.clamp(0.0, 1.0);
                }
              }

              // 格式化剩余时间显示
              String remainingTimeText = '截止: ${item.endTime}';
              if (endTime != GlobalUtils.timeNull) {
                if (now.isAfter(endTime)) {
                  remainingTimeText = '已截止';
                } else {
                  final remaining = endTime.difference(now);
                  if (remaining.inDays > 0) {
                    remainingTimeText = '剩余${remaining.inDays}天';
                  } else if (remaining.inHours > 0) {
                    remainingTimeText = '剩余${remaining.inHours}小时';
                  } else {
                    remainingTimeText = '剩余${remaining.inMinutes}分钟';
                  }
                }
              }

              // 将DDLItem转换为任务数据格式
              _taskData.add({
                'id': item.id, // 保存ID以便后续更新和删除
                'title': item.name,
                'note': item.note,
                'remainingTime': remainingTimeText,
                'progress': progress,
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

    initializeConnection();
  }

  Future<void> addTask(String title, String note, String timeText) async {
    try {
      // 假设timeText是一个日期时间字符串
      final endTime = GlobalUtils.safeParseDateTime(timeText);
      final now = DateTime.now();
      final startTime = now.toIso8601String(); // 使用当前时间作为开始时间

      if (endTime != GlobalUtils.timeNull) {
        // 创建新的DDL项目
        final id = await webUtils.createDDL(
          title,
          startTime,
          timeText, // 使用原始时间文本作为结束时间
          note,
          DeadlineType.TASK, // 默认类型为任务
        );

        // 计算进度和剩余时间显示
        double progress = 0.0;
        String remainingTimeText = timeText;

        // 格式化剩余时间显示
        if (now.isAfter(endTime)) {
          remainingTimeText = '已截止';
          progress = 1.0;
        } else {
          final remaining = endTime.difference(now);
          if (remaining.inDays > 0) {
            remainingTimeText = '剩余${remaining.inDays}天';
          } else if (remaining.inHours > 0) {
            remainingTimeText = '剩余${remaining.inHours}小时';
          } else {
            remainingTimeText = '剩余${remaining.inMinutes}分钟';
          }

          // 计算进度
          final totalDuration = endTime.difference(now).inMilliseconds;
          final elapsedDuration = 0; // 刚刚开始，所以已经过去的时间为0
          progress = totalDuration > 0 ? elapsedDuration / totalDuration : 0.0;
        }

        // 更新UI
        setState(() {
          _taskData.add({
            'id': id, // 保存ID以便后续更新和删除
            'title': title,
            'note': note,
            'remainingTime': remainingTimeText,
            'progress': progress,
          });
        });
      }
    } catch (e) {
      // 处理错误
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建任务失败: $e')));
      }
    }
  }

  Future<void> updateTask(
    int index,
    String title,
    String note,
    String timeText,
  ) async {
    try {
      // 获取任务ID
      final taskId = _taskData[index]['id'];
      if (taskId == null) {
        throw Exception('任务ID不存在');
      }

      // 假设timeText是一个日期时间字符串
      final endTime = GlobalUtils.safeParseDateTime(timeText);
      final now = DateTime.now();

      // 准备更新数据
      final Map<String, dynamic> updates = {
        'name': title,
        'note': note,
        'endTime': timeText,
      };

      // 调用API更新任务
      final success = await webUtils.updateDDL(taskId, updates);

      if (success) {
        // 计算新的进度和剩余时间
        double progress = 0.0;
        String remainingTimeText = timeText;

        if (endTime != GlobalUtils.timeNull) {
          // 格式化剩余时间显示
          if (now.isAfter(endTime)) {
            remainingTimeText = '已截止';
            progress = 1.0;
          } else {
            final remaining = endTime.difference(now);
            if (remaining.inDays > 0) {
              remainingTimeText = '剩余${remaining.inDays}天';
            } else if (remaining.inHours > 0) {
              remainingTimeText = '剩余${remaining.inHours}小时';
            } else {
              remainingTimeText = '剩余${remaining.inMinutes}分钟';
            }

            // 假设任务从现在开始重新计算进度
            final startTime = now;
            final totalDuration = endTime.difference(startTime).inMilliseconds;
            final elapsedDuration = 0; // 更新时重置进度
            progress =
                totalDuration > 0 ? elapsedDuration / totalDuration : 0.0;
          }
        } else {
          // 如果解析失败，保持当前进度
          progress = _taskData[index]['progress'];
        }

        // 更新UI
        setState(() {
          _taskData[index]['title'] = title;
          _taskData[index]['note'] = note;
          _taskData[index]['remainingTime'] = remainingTimeText;
          _taskData[index]['progress'] = progress;
        });
      } else {
        throw Exception('更新任务失败');
      }
    } catch (e) {
      // 处理错误
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新任务失败: $e')));
      }
    }
  }

  Future<void> deleteTask(int index) async {
    try {
      // 获取任务ID
      final taskId = _taskData[index]['id'];
      if (taskId == null) {
        throw Exception('任务ID不存在');
      }

      // 调用API删除任务
      final success = await webUtils.deleteDDL(taskId);

      if (success) {
        // 更新UI
        setState(() {
          _taskData.removeAt(index);
        });
      } else {
        throw Exception('删除任务失败');
      }
    } catch (e) {
      // 处理错误
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除任务失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    if (screenWidth >= 1200) {
      crossAxisCount = 3;
    } else if (screenWidth >= 800) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return Expanded(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3, // 控制任务卡片比例，宽高比为3:1
              ),
              itemCount: _taskData.length,
              itemBuilder: (context, index) {
                final task = _taskData[index];
                return DDLItemWidget(
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
                      onConfirm: (newTitle, newNote, newTime) async {
                        await updateTask(index, newTitle, newNote, newTime);
                      },
                      onDelete: () async {
                        await deleteTask(index);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () {
                TaskUtils.onFABPressed(
                  context,
                  onTaskAdd: (title, note, timeText) async {
                    await addTask(title, note, timeText);
                  },
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class DDLItemWidget extends StatelessWidget {
  final String title;
  final String remainingTime;
  final String note;
  final double progress;
  final VoidCallback? onTap;

  const DDLItemWidget({
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
        elevation: 0, // 去掉阴影
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ), // 加大 margin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // 圆角更大
        ),
        clipBehavior: Clip.hardEdge,
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(context),
              const SizedBox(height: 6),
              Expanded(child: _buildNoteRow(context)),
              const SizedBox(height: 8),
              _buildProgressBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        note,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
    );
  }
}

class TaskUtils {
  static void onFABPressed(
    BuildContext context, {
    required Future<void> Function(String title, String note, String timeText)
    onTaskAdd,
  }) {
    _showTaskDialog(context, onConfirm: onTaskAdd);
  }

  static void showEditDialog(
    BuildContext context, {
    required String initialTitle,
    required String initialNote,
    required String initialTime,
    required Future<void> Function(String title, String note, String timeText)
    onConfirm,
    required Future<void> Function() onDelete,
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
    required Future<void> Function(String title, String note, String timeText)
    onConfirm,
    Future<void> Function()? onDelete,
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
              if (selectedDate == null && selectedTime == null) {
                return initialTime;
              }

              // 如果没有选择日期，则使用当前日期
              final date = selectedDate ?? DateTime.now();

              // 如果没有选择时间，则使用23:59作为默认时间
              final time =
                  selectedTime ?? const TimeOfDay(hour: 23, minute: 59);

              // 创建完整的DateTime对象
              final dateTime = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );

              // 格式化为ISO 8601格式，与GlobalUtils.parseDateTime兼容
              return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}T${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";
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
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop(); // 先关闭对话框
                      await onDelete(); // 执行删除操作
                    },
                    child: const Text('删除'),
                  ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // 先关闭对话框
                    await onConfirm(
                      // 执行确认操作
                      titleController.text,
                      noteController.text,
                      formattedDateTime(),
                    );
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
